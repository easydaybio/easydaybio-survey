-- 온츄 시식 설문 DB 구조
-- 새 Supabase 프로젝트의 SQL Editor에 통째로 붙여넣어 한 번 실행합니다.

-- 1. 운영자 목록 ---------------------------------------------------------
create table public.admins (
  email text primary key
);
alter table public.admins enable row level security;  -- 정책 없음: 직접 조회 불가

create function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.admins a
    where lower(a.email) = lower((select auth.jwt() ->> 'email'))
  );
$$;

-- 2. 행사 (QR 하나 = 행사 하나) -------------------------------------------
create table public.events (
  id uuid primary key default gen_random_uuid(),
  token text not null unique default encode(extensions.gen_random_bytes(6), 'hex'),
  name text not null check (char_length(name) between 1 and 100),
  event_date date not null default current_date,
  place text check (char_length(place) <= 100),
  event_type text not null check (event_type in ('tasting', 'product')),
  product_version text not null default 'V1' check (char_length(product_version) <= 20),
  lot text check (char_length(lot) <= 50),
  note text check (char_length(note) <= 500),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.events enable row level security;
create policy events_admin on public.events for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- 3. 응답 (한 사람의 시식 한 번 = 한 줄) ------------------------------------
create table public.responses (
  response_id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id),
  event_type text not null check (event_type in ('tasting', 'product')),
  product_version text not null,
  lot text,
  created_at timestamptz not null default now(),

  -- 응답자 기본
  age_group text not null check (age_group in ('20s', '30s', '40s', '50s', '60plus')),
  gender text not null check (gender in ('female', 'male', 'na')),
  bloating_freq text not null check (bloating_freq in ('rare', 'sometimes', 'often')),
  supplement_use boolean not null,
  mint_pref smallint not null check (mint_pref between 1 and 5),
  chewable_exp boolean not null,
  expect_score smallint not null check (expect_score between 1 and 5),

  -- 맛과 식감
  q_mint smallint not null check (q_mint between 1 and 5),
  q_sweet smallint not null check (q_sweet between 1 and 5),
  q_bitter smallint not null check (q_bitter between 1 and 5),
  q_aftertaste smallint not null check (q_aftertaste between 1 and 5),
  q_texture smallint not null check (q_texture between 1 and 5),
  q_size smallint not null check (q_size between 1 and 5),
  q_easy_chew smallint not null check (q_easy_chew between 1 and 5),
  q_refresh smallint not null check (q_refresh between 1 and 5),
  q_overall smallint not null check (q_overall between 1 and 5),

  -- 구매 의향과 가격
  q_repurchase smallint not null check (q_repurchase between 1 and 5),
  price_accept integer not null check (price_accept between 0 and 1000000),
  q_price_fit text not null check (q_price_fit in ('expensive', 'fair', 'cheap')),
  q_recommend smallint not null check (q_recommend between 0 and 10),
  use_timing text check (use_timing in ('right_after', 'within_1h', 'other')),

  -- 좋았던 점 / 아쉬웠던 점 (복수 선택)
  good_points text[] not null check (
    cardinality(good_points) >= 1 and
    good_points <@ array['taste', 'digest', 'refresh', 'usability', 'repeat', 'longterm', 'other', 'none']
  ),
  bad_points text[] not null check (
    cardinality(bad_points) >= 1 and
    bad_points <@ array['taste', 'digest', 'refresh', 'usability', 'repeat', 'longterm', 'other', 'none']
  ),
  good_other text check (char_length(good_other) <= 100),
  bad_other text check (char_length(bad_other) <= 100),
  open_comment text check (char_length(open_comment) <= 500),
  consent_quote boolean,

  -- 제품 제공 유형에만
  use_days text check (use_days in ('d1_2', 'd3_6', 'd7plus')),
  use_per_day smallint check (use_per_day between 1 and 20),
  use_timing_actual text check (use_timing_actual in ('right_after', 'within_1h', 'other')),
  q_comfort smallint check (q_comfort between 1 and 5),   -- 내부 분석 전용
  q_continue smallint check (q_continue between 1 and 5),

  constraint tasting_fields check (event_type <> 'tasting' or use_timing is not null),
  constraint product_fields check (
    event_type <> 'product' or (
      use_days is not null and use_per_day is not null and use_timing_actual is not null
      and q_comfort is not null and q_continue is not null
    )
  )
);
create index responses_event_idx on public.responses (event_id);
alter table public.responses enable row level security;
create policy responses_admin_read on public.responses for select to authenticated
  using ((select public.is_admin()));
create policy responses_admin_delete on public.responses for delete to authenticated
  using ((select public.is_admin()));

-- 4. 개선 기록 -------------------------------------------------------------
create table public.improvements (
  id uuid primary key default gen_random_uuid(),
  logged_on date not null default current_date,
  product_version text not null default 'V1',
  observation text not null check (char_length(observation) between 1 and 1000),  -- 어떤 반응을 보고
  change text not null check (char_length(change) between 1 and 1000),            -- 무엇을 바꿨는지
  created_at timestamptz not null default now()
);
alter table public.improvements enable row level security;
create policy improvements_admin on public.improvements for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- 5. 응답자용 함수 (로그인 없이 호출) ---------------------------------------
-- 응답자는 표를 직접 읽거나 쓸 수 없고, 이 두 함수만 쓸 수 있습니다.

create function public.get_event(p_token text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'event_type', e.event_type,
    'product_version', e.product_version,
    'is_active', e.is_active
  )
  from public.events e where e.token = p_token;
$$;

create function public.submit_response(p_token text, p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  e public.events;
  r public.responses;
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

  insert into public.responses values (r.*);
  return r.response_id;
end;
$$;

revoke all on function public.is_admin() from public, anon;
revoke all on function public.get_event(text) from public;
revoke all on function public.submit_response(text, jsonb) from public;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.get_event(text) to anon, authenticated;
grant execute on function public.submit_response(text, jsonb) to anon, authenticated;

-- 6. 운영자 등록 -----------------------------------------------------------
-- 아래 주소를 운영자 이메일로 바꿔 실행합니다. 이 목록에 있는 계정만 관리 화면을 볼 수 있습니다.
-- insert into public.admins (email) values ('운영자@example.com');
