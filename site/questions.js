// 문항 정의. 설문 페이지와 관리 화면이 함께 씁니다.
// only: 'tasting' = 현장 시식에만, 'product' = 제품 제공에만 보입니다.
(function () {
  const scale = (id, label, lo, hi, extra) =>
    Object.assign({ id, label, type: "scale", min: 1, max: 5, lo, hi }, extra || {});
  const TIMING = [
    ["right_after", "식사 직후"],
    ["within_1h", "식사 후 1시간 이내"],
    ["other", "그 밖의 때"],
  ];
  const POINTS = [
    ["taste", "맛"],
    ["digest", "소화 효과", null, "먹고 나서 속이 편한지"],
    ["refresh", "입가심 효과", null, "먹고 난 뒤 입안이 개운한지"],
    ["usability", "사용성", null, "꺼내서 물 없이 먹기 편한지"],
    ["repeat", "반복 복용성", null, "끼니마다 먹어도 부담 없는지"],
    ["longterm", "지속 복용성", null, "여러 날 계속 먹을 만한지"],
    ["other", "기타"],
    ["none", "없음"],
  ].map(([value, label, only, hint]) => ({ value, label, only, hint }));

  window.SURVEY = {
    PRICE: 24900,
    steps: [
      {
        title: "먼저 몇 가지만 여쭐게요",
        items: [
          { id: "age_group", label: "연령대", type: "choice",
            options: [["20s", "20대"], ["30s", "30대"], ["40s", "40대"], ["50s", "50대"], ["60plus", "60대 이상"]] },
          { id: "gender", label: "성별", type: "choice",
            options: [["female", "여성"], ["male", "남성"], ["na", "답하지 않음"]] },
          { id: "bloating_freq", label: "식후에 불편을 느끼는 빈도는 어느 정도인가요?", type: "choice",
            options: [["rare", "거의 없음"], ["sometimes", "가끔"], ["often", "자주"]] },
          { id: "supplement_use", label: "지금 소화 관련 보조제를 드시나요?", type: "bool" },
          scale("mint_pref", "평소 민트 맛을 좋아하시나요?", "싫어함", "아주 좋아함"),
          { id: "chewable_exp", label: "씹어 먹는 정제를 드셔 보신 적이 있나요?", type: "bool" },
          scale("expect_score", "먹기 전에 기대했던 정도", "기대 없음", "기대 큼"),
        ],
      },
      {
        title: "드신 경험",
        only: "product",
        items: [
          { id: "use_days", label: "며칠 동안 드셨나요?", type: "choice",
            options: [["d1_2", "1~2일"], ["d3_6", "3~6일"], ["d7plus", "7일 이상"]] },
          { id: "use_per_day", label: "하루에 보통 몇 정 드셨나요?", type: "number", min: 1, max: 20, unit: "정" },
          { id: "use_timing_actual", label: "주로 언제 드셨나요?", type: "choice", options: TIMING },
          scale("q_comfort", "먹은 뒤 속이 편했나요?", "전혀 아님", "아주 편함"),
          scale("q_continue", "앞으로도 계속 먹을 의향", "전혀 없음", "아주 있음"),
        ],
      },
      {
        title: "맛과 식감",
        items: [
          scale("q_mint", "민트 향 강도", "아주 약함", "아주 강함", { mid: "적당", jar: true }),
          scale("q_sweet", "단맛", "아주 약함", "아주 강함", { mid: "적당", jar: true }),
          scale("q_bitter", "쓴맛", "없음", "아주 강함", { lowIsGood: true }),
          scale("q_aftertaste", "뒷맛(잔맛)", "깔끔함", "아주 남음", { lowIsGood: true }),
          scale("q_texture", "식감", "딱딱함", "부드러움", { mid: "적당", jar: true }),
          scale("q_size", "크기", "아주 작음", "아주 큼", { mid: "적당", jar: true }),
          scale("q_easy_chew", "물 없이 씹어 먹기 편했나요?", "아주 불편", "아주 편함"),
          scale("q_refresh", "먹고 난 뒤 입안 느낌", "불편함", "상쾌함"),
          scale("q_overall", "전체적으로 맛이 어땠나요?", "별로", "아주 좋음"),
        ],
      },
      {
        title: "구매 의향과 가격",
        items: [
          scale("q_repurchase", "다시 사 먹을 의향", "전혀 없음", "아주 있음"),
          { id: "price_accept", label: "1병(40정)에 얼마면 사도 된다고 느끼시나요?", type: "number",
            min: 0, max: 1000000, unit: "원", step: 100, placeholder: "예: 20000" },
          { id: "q_price_fit", label: "1병(40정) 24,900원은 어떻게 느껴지나요?", type: "choice",
            options: [["expensive", "비싸다"], ["fair", "적당하다"], ["cheap", "저렴하다"]] },
          { id: "q_recommend", label: "주변에 추천할 의향", type: "scale", min: 0, max: 10,
            lo: "전혀 없음", hi: "꼭 추천" },
          { id: "use_timing", label: "식후에 먹는다면 언제 먹을 것 같나요?", type: "choice",
            options: TIMING, only: "tasting" },
        ],
      },
      {
        title: "마지막이에요",
        items: [
          { id: "good_points", label: "좋았던 점을 모두 골라 주세요", type: "multi", options: POINTS, otherId: "good_other" },
          { id: "bad_points", label: "아쉬웠던 점을 모두 골라 주세요", type: "multi", options: POINTS, otherId: "bad_other" },
          { id: "open_comment", label: "남기고 싶은 한마디 (선택)", type: "text", optional: true, maxLength: 500 },
          { id: "consent_quote", label: "이 한마디를 홈페이지나 SNS에 인용해도 괜찮나요? (이름은 쓰지 않습니다)",
            type: "bool", showIf: (a) => !!(a.open_comment && a.open_comment.trim()) },
        ],
      },
    ],
  };

  // 관리 화면용: 값 → 한글 라벨
  window.SURVEY.items = {};
  window.SURVEY.steps.forEach((s) =>
    s.items.forEach((it) => {
      window.SURVEY.items[it.id] = it;
    })
  );
  window.SURVEY.labelOf = function (id, value) {
    const it = window.SURVEY.items[id];
    if (!it) return value;
    if (it.type === "bool") return value ? "예" : "아니오";
    if (it.type === "choice") {
      const o = it.options.find((x) => x[0] === value);
      return o ? o[1] : value;
    }
    if (it.type === "multi") {
      const o = it.options.find((x) => x.value === value);
      return o ? o.label : value;
    }
    return value;
  };
})();
