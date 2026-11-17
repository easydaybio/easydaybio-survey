-- 설문을 13문항으로 줄였습니다 (2026-11).
-- 더 묻지 않는 문항의 열은 지우지 않고 비워 둘 수 있게만 바꿉니다. 이전 응답은 그대로 남습니다.
--   소화 보조제 복용, 씹어 먹는 정제 경험, 먹기 전 기대, 쓴맛, 크기,
--   씹어 먹기 편함, 입안 느낌, 수용 가격, 식후 복용 시점(예상)
alter table public.responses
  alter column supplement_use drop not null,
  alter column chewable_exp drop not null,
  alter column expect_score drop not null,
  alter column q_bitter drop not null,
  alter column q_size drop not null,
  alter column q_easy_chew drop not null,
  alter column q_refresh drop not null,
  alter column price_accept drop not null;
alter table public.responses drop constraint tasting_fields;

-- 식감 문항도 뺐습니다.
alter table public.responses alter column q_texture drop not null;
