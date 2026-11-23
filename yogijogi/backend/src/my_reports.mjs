// 마이페이지 API: 내 제보 목록, 처리 단계 이력, 담당자 답변 조회.
//
// - GET /me/reports       내 제보 목록 (최근 상태 변경 순)
// - GET /me/reports/{id}  내 제보 한 건
//
// 로그인이 정해지기 전까지는 고정 데모 사용자의 샘플 데이터로만 응답하고
// isDemo: true를 함께 보낸다. 담당자 답변도 모두 가상 답변(isDemo: true)이다.
//
// 저장소(store)는 아래 인터페이스만 지키면 교체할 수 있다. AWS DB와 연동할 때는
// DynamoDB 등을 읽는 store를 만들어 handleMyReportRequest의 options로 넘긴다.
//   listByUser(userId) → Promise<MyReport[]>
//   getByUser(userId, id) → Promise<MyReport | undefined>

const UTC_OFFSET = '+09:00';
const UTC_OFFSET_MINUTES = 9 * 60;
const TIME_ZONE = 'Asia/Seoul';

export const DEMO_USER_ID = 'demo-user';

export const REPORT_STAGES = ['received', 'checking', 'in_progress', 'resolved'];

function respond(statusCode, body) {
  return {
    statusCode,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(body),
  };
}

// 서울 기준 오늘 날짜(YYYY-MM-DD)에서 days일 전의 hh:mm 시각(ISO 8601, +09:00).
function seoulTime(now, days, hhmm) {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-US', {
      timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit',
    }).formatToParts(now).map(({ type, value }) => [type, value]),
  );
  const date = new Date(Date.UTC(+parts.year, +parts.month - 1, +parts.day - days));
  return `${date.toISOString().slice(0, 10)}T${hhmm}:00${UTC_OFFSET}`;
}

// 샘플 제보 정의. 처리 이력은 [단계, 며칠 전, 시각] 목록이다.
const sampleReports = [
  {
    id: 'demo-1', type: '벌레 몬스터', location: '중앙도서관 보관실 앞 (B1)',
    description: '보관실 앞 복도에서 바퀴벌레를 봤어요.',
    history: [['received', 0, '11:20'], ['checking', 0, '11:45'], ['in_progress', 0, '13:10']],
    response: {
      department: '학생지원처', message: '방역업체에 작업 지시를 전달했어요.',
      plan: '오늘 18:00 야간 방역 예정', at: [0, '13:10'],
    },
  },
  {
    id: 'demo-2', type: '비흡연구역 흡연', location: '수정관 동편 계단 (1F)',
    description: '계단 출입구 근처에서 담배 냄새가 나요.',
    history: [['received', 0, '09:05']],
  },
  {
    id: 'demo-3', type: '시설 고장 / 파손', location: '과학관 정수기 (1F)',
    description: '정수기 아래로 물이 새고 있어요.',
    history: [['received', 2, '10:00'], ['checking', 2, '11:30'], ['in_progress', 2, '14:00'], ['resolved', 2, '16:30']],
    response: { department: '시설관리팀', message: '정수기 배관을 교체했어요.', at: [2, '16:30'] },
  },
  {
    id: 'demo-4', type: '기타 불편 / 제안', location: '성신관 라운지 (2F)',
    description: '라운지 의자 몇 개가 흔들려요.',
    history: [['received', 4, '15:00'], ['checking', 4, '17:00'], ['resolved', 3, '11:00']],
    response: { department: '시설관리팀', message: '흔들리는 의자를 교체했어요.', at: [3, '11:00'] },
  },
  {
    id: 'demo-5', type: '시설 고장 / 파손', location: '수정관 강의실 복도 조명 (3F)',
    description: '복도 조명 하나가 깜빡거려요.',
    history: [['received', 6, '09:30'], ['in_progress', 6, '13:00'], ['resolved', 5, '10:00']],
    response: { department: '시설관리팀', message: '조명 안정기를 교체했어요.', at: [5, '10:00'] },
  },
  {
    id: 'demo-6', type: '벌레 몬스터', location: '난향관 식당 출입구 (1F)',
    description: '출입구 근처에 날벌레가 많아요.',
    history: [['received', 9, '12:10'], ['checking', 9, '15:00'], ['in_progress', 8, '10:00'], ['resolved', 7, '18:00']],
    response: { department: '학생지원처', message: '출입구 주변 방역을 마쳤어요.', at: [7, '18:00'] },
  },
  {
    id: 'demo-7', type: '비흡연구역 흡연', location: '수정캠퍼스 정문 옆',
    description: '정문 옆 벤치 주변에 꽁초가 많아요.',
    history: [['received', 12, '17:40'], ['checking', 11, '09:00'], ['resolved', 10, '14:00']],
    response: { department: '총무팀', message: '금연 안내 표지를 추가로 설치했어요.', at: [10, '14:00'] },
  },
];

// 제보 API(/reports)와 같은 필드에 statusHistory, staffResponse를 더한 형태.
export function buildMyReport(sample, now) {
  const statusHistory = sample.history.map(([status, days, hhmm]) => ({
    status, changedAt: seoulTime(now, days, hhmm),
  }));
  const last = statusHistory[statusHistory.length - 1];
  const { response } = sample;
  return {
    id: sample.id,
    type: sample.type,
    location: sample.location,
    description: sample.description,
    occurredAt: statusHistory[0].changedAt,
    status: last.status,
    source: 'user_report',
    updatedAt: last.changedAt,
    statusHistory,
    staffResponse: response ? {
      department: response.department,
      message: response.message,
      plan: response.plan ?? null,
      respondedAt: seoulTime(now, ...response.at),
      // 실제 담당 부서와 연동되기 전에는 항상 가상 답변으로 표시한다.
      isDemo: true,
    } : null,
  };
}

// 샘플 저장소. 데모 사용자에게만 샘플 제보를 돌려준다.
export function createSampleMyReportStore(clock = () => new Date()) {
  const forUser = (userId) => (userId === DEMO_USER_ID
    ? sampleReports.map((sample) => buildMyReport(sample, clock()))
    : []);
  return {
    async listByUser(userId) { return forUser(userId); },
    async getByUser(userId, id) { return forUser(userId).find((report) => report.id === id); },
  };
}

const defaultStore = createSampleMyReportStore();

// /me/reports 경로가 아니면 null을 반환해 다른 라우트가 처리하게 한다.
export async function handleMyReportRequest(method, path, {
  store = defaultStore,
  // 로그인이 연결되면 요청의 인증 정보에서 사용자 ID를 꺼내도록 바꾼다.
  resolveUserId = () => DEMO_USER_ID,
  isDemo = true,
} = {}) {
  const match = /^\/me\/reports(?:\/([a-z0-9-]{1,64}))?$/.exec(path);
  if (!match) return null;
  if (method !== 'GET') return respond(405, { error: 'method_not_allowed' });

  const [, id] = match;
  const userId = resolveUserId();
  try {
    if (id) {
      const item = await store.getByUser(userId, id);
      return item
        ? respond(200, { item, isDemo, utcOffsetMinutes: UTC_OFFSET_MINUTES })
        : respond(404, { error: 'not_found' });
    }
    const items = (await store.listByUser(userId))
      .sort((a, b) => Date.parse(b.updatedAt) - Date.parse(a.updatedAt));
    return respond(200, { items, isDemo, utcOffsetMinutes: UTC_OFFSET_MINUTES });
  } catch (error) {
    console.error('My report storage operation failed', error.name);
    return respond(500, { error: 'internal_error' });
  }
}
