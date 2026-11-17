-- "연락 완료"에 체크한 날짜를 기록합니다.
-- 동의받은 보유 기간이 "제품 출고 안내 후 1개월"이라, 이 날짜로부터 1개월을 셉니다.
alter table public.reservations add column contacted_on date;
alter table public.reservations alter column created_on set default ((now() at time zone 'Asia/Seoul')::date);

create function public.reservations_set_contacted_on() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.contacted and not old.contacted then
    new.contacted_on := (now() at time zone 'Asia/Seoul')::date;   -- 체크한 날 (한국 날짜)
  elsif not new.contacted then
    new.contacted_on := null;                                       -- 체크를 풀면 날짜도 지움
  else
    new.contacted_on := old.contacted_on;                           -- 날짜는 직접 고칠 수 없음
  end if;
  return new;
end;
$$;
revoke all on function public.reservations_set_contacted_on() from public, anon, authenticated;

create trigger reservations_contacted_on before update on public.reservations
  for each row execute function public.reservations_set_contacted_on();
