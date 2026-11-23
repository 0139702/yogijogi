// 강의실 상세 API.
// 실제 학사 시간표와 연동되기 전까지 아래 샘플 데이터로만 응답하고,
// 응답에 isSample: true를 담아 앱에서 샘플임을 표시하게 한다.

const TIME_ZONE = 'Asia/Seoul';
const UTC_OFFSET = '+09:00';
const UTC_OFFSET_MINUTES = 9 * 60;

// 샘플 시간표를 마지막으로 정리한 시각.
const SAMPLE_UPDATED_AT = '2026-11-20T09:00:00+09:00';

const weekdaySchedule = [
  { title: '컴퓨터그래픽스', start: '10:00', end: '12:00' },
  { title: '공강 / 자율 개방', start: '12:00', end: '14:00', isOpenUse: true },
  { title: '모바일UX디자인', start: '14:00', end: '16:00' },
];

const sampleClassrooms = new Map([
  ['eng2-204', {
    id: 'eng2-204',
    buildingName: '공학관 2호관',
    roomName: '204호 멀티미디어실',
    facilities: ['콘센트 전좌석', '빔프로젝터', 'Wi-Fi 6', '냉난방 가동'],
    // 요일(1=월 ... 7=일)별 시간표. 주말은 수업이 없다.
    weeklySchedule: { 1: weekdaySchedule, 2: weekdaySchedule, 3: weekdaySchedule, 4: weekdaySchedule, 5: weekdaySchedule },
    sampleReports: [
      { id: 'sample-report-1', description: '에어컨 바람이 조금 약해요', minutesAgo: 30 },
    ],
  }],
]);

function respond(statusCode, body) {
  return {
    statusCode,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(body),
  };
}

// 서울 기준 날짜(YYYY-MM-DD)와 요일(1=월 ... 7=일).
function seoulDate(now) {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-US', {
      timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit', weekday: 'short',
    }).formatToParts(now).map(({ type, value }) => [type, value]),
  );
  const weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(parts.weekday) + 1;
  return { date: `${parts.year}-${parts.month}-${parts.day}`, weekday };
}

export function buildClassroomDetail(classroom, now) {
  const { date, weekday } = seoulDate(now);
  const schedule = (classroom.weeklySchedule[weekday] ?? []).map((session) => ({
    title: session.title,
    start: `${date}T${session.start}:00${UTC_OFFSET}`,
    end: `${date}T${session.end}:00${UTC_OFFSET}`,
    isOpenUse: session.isOpenUse ?? false,
  }));
  const recentReports = classroom.sampleReports.map((report) => ({
    id: report.id,
    description: report.description,
    source: 'user_report',
    status: 'received',
    reportedAt: new Date(now.getTime() - report.minutesAgo * 60_000).toISOString(),
  }));
  return {
    id: classroom.id,
    buildingName: classroom.buildingName,
    roomName: classroom.roomName,
    // 사용자 위치·경로 데이터가 연결되기 전에는 도보 시간을 제공하지 않는다.
    walkingMinutes: null,
    facilities: classroom.facilities,
    schedule,
    recentReports,
    updatedAt: SAMPLE_UPDATED_AT,
    // 앱이 기기 시간대와 관계없이 캠퍼스 시각으로 표시하도록 알려준다.
    utcOffsetMinutes: UTC_OFFSET_MINUTES,
    isSample: true,
  };
}

// /classrooms 경로가 아니면 null을 반환해 다른 라우트가 처리하게 한다.
export function handleClassroomRequest(method, path, now = new Date()) {
  const match = /^\/classrooms\/([a-z0-9-]{1,64})$/.exec(path);
  if (!match) return null;
  if (method !== 'GET') return respond(405, { error: 'method_not_allowed' });

  const classroom = sampleClassrooms.get(match[1]);
  if (!classroom) return respond(404, { error: 'not_found' });
  return respond(200, buildClassroomDetail(classroom, now));
}
