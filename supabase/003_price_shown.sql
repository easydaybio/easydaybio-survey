-- 응답자가 설문에서 본 정가를 응답마다 기록합니다.
-- 정가가 바뀌어도 "그 가격을 어떻게 느꼈는지"를 가격별로 나눠 볼 수 있습니다.
alter table public.responses add column price_shown integer check (price_shown between 0 and 1000000);
-- 이 열이 생기기 전의 응답은 모두 24,900원을 보고 답했습니다.
update public.responses set price_shown = 24900 where price_shown is null;
