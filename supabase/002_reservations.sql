-- 구매 예약 전화번호 수집
-- schema.sql 다음에 실행합니다.
--
-- 전화번호는 설문 응답과 다른 표에 두고, 서로 연결하는 값을 남기지 않습니다.
-- 응답에는 "예약을 남겼는지"(reserved)만 예/아니오로 기록합니다.
-- 접수 시각도 날짜까지만 남겨, 시각으로 응답과 맞춰 볼 수 없게 합니다.

alter table public.events add column collect_reservation boolean not null default false;
alter table public.responses add column reserved boolean not null default false;

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id),
  phone text not null check (phone ~ '^01[016789][0-9]{7,8}$'),
  consent boolean not null check (consent),          -- 수집·이용 동의를 받은 건만 저장
  created_on date not null default current_date,
  contacted boolean not null default false,          -- 연락 완료 여부
  unique (event_id, phone)
);
create index reservations_event_idx on public.reservations (event_id);
alter table public.reservations enable row level security;
create policy reservations_admin_read on public.reservations for select to authenticated
  using ((select public.is_admin()));
create policy reservations_admin_update on public.reservations for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy reservations_admin_delete on public.reservations for delete to authenticated
  using ((select public.is_admin()));

create or replace function public.get_event(p_token text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'event_type', e.event_type,
    'product_version', e.product_version,
    'is_active', e.is_active,
    'collect_reservation', e.collect_reservation
  )
  from public.events e where e.token = p_token;
$$;

create or replace function public.submit_response(p_token text, p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  e public.events;
  r public.responses;
  v_phone text;
begin
  select * into e from public.events where token = p_token;
  if not found or not e.is_active then
    raise exception 'event_closed';
  end if;

  r := jsonb_populate_record(null::public.responses, p);

  -- 자동 기록 값은 응답자가 보낸 값을 무시하고 행사에서 가져옵니다.
  r.response_id := gen_random_uuid();
  r.event_id := e.id;
  r.event_type := e.event_type;
  r.product_version := e.product_version;
  r.lot := e.lot;
  r.created_at := now();

  if e.event_type = 'tasting' then
    r.use_days := null; r.use_per_day := null; r.use_timing_actual := null;
    r.q_comfort := null; r.q_continue := null;
  else
    r.use_timing := null;
  end if;
  if r.open_comment is null or btrim(r.open_comment) = '' then
    r.open_comment := null; r.consent_quote := null;
  end if;

  -- 구매 예약: 행사에서 받기로 한 경우에만, 숫자만 남겨 확인합니다.
  r.reserved := false;
  v_phone := regexp_replace(coalesce(p ->> 'reserve_phone', ''), '[^0-9]', '', 'g');
  if e.collect_reservation and v_phone <> '' then
    if coalesce((p ->> 'reserve_consent')::boolean, false) is not true then
      raise exception 'consent_required';
    end if;
    if v_phone !~ '^01[016789][0-9]{7,8}$' then
      raise exception 'invalid_phone';
    end if;
    r.reserved := true;
  end if;

  insert into public.responses values (r.*);

  if r.reserved then
    insert into public.reservations (event_id, phone, consent)
    values (e.id, v_phone, true)
    on conflict (event_id, phone) do nothing;
  end if;

  return r.response_id;
end;
$$;
