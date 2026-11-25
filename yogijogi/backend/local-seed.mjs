// 로컬 API 서버가 켜질 때 제보 피드에 미리 넣어 두는 샘플 제보.
// 서버를 재시작해도 같은 샘플로 다시 채운다. SEED_REPORTS=false면 넣지 않는다.

import { randomUUID } from 'node:crypto';

// 앱의 시연용 로그인은 앱을 켠 뒤 처음 가입한 계정에 'demo-1'을 붙인다.
// 이 ID로 표시한 샘플은 그 계정의 "내 제보"가 되어 수정·삭제 흐름을 시연할 수 있다.
const DEMO_AUTHOR_ID = 'demo-1';

// [유형, 위치, 설명, 처리 상태, 몇 시간 전, 작성자] — 오래된 것부터 적는다.
const sampleReports = [
  ['벌레 몬스터', '난향관 식당 출입구 (1F)', '출입구 쪽 창틀에 벌집이 생긴 것 같아요.', 'in_progress', 50],
  ['시설 고장 / 파손', '과학관 정수기 (1F)', '정수기에서 물이 안 나와요.', 'in_progress', 30, DEMO_AUTHOR_ID],
  ['비흡연구역 흡연', '수정관 동편 계단 (1F)', '계단 옆에서 담배 냄새가 계속 올라와요.', 'received', 20],
  ['시설 고장 / 파손', '수정관 3층 복도', '복도 조명이 계속 깜빡여요.', 'received', 6],
  ['벌레 몬스터', '중앙도서관 보관실 앞 (B1)', '보관실 앞 복도에서 바퀴벌레를 봤어요.', 'received', 1],
];

export function seedReports(items, now = new Date()) {
  for (const [type, location, description, status, hoursAgo, authorId] of sampleReports) {
    const time = new Date(now.getTime() - hoursAgo * 60 * 60 * 1000).toISOString();
    const id = randomUUID();
    items.set(id, {
      id, type, location, description, status, source: 'user_report',
      ...(authorId && { authorId }),
      occurredAt: time, createdAt: time, updatedAt: time,
    });
  }
}
