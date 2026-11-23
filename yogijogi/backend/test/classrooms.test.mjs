// 실행: node --test backend/test/
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHandler } from '../src/api.mjs';
import { handleClassroomRequest } from '../src/classrooms.mjs';

const handler = createHandler({}, { environment: 'test', reportsEnabled: false });
const request = (method, path) => handler({ rawPath: path, requestContext: { http: { method } } });

// 2026-11-20(금) 12:30 서울 시각
const friday = new Date('2026-11-20T03:30:00Z');

test('returns sample classroom detail with today schedule in Seoul time', () => {
  const response = handleClassroomRequest('GET', '/classrooms/eng2-204', friday);
  assert.equal(response.statusCode, 200);
  const body = JSON.parse(response.body);
  assert.equal(body.roomName, '204호 멀티미디어실');
  assert.equal(body.isSample, true);
  assert.equal(body.walkingMinutes, null);
  assert.equal(body.utcOffsetMinutes, 540);
  assert.deepEqual(body.facilities, ['콘센트 전좌석', '빔프로젝터', 'Wi-Fi 6', '냉난방 가동']);
  assert.equal(body.schedule.length, 3);
  assert.equal(body.schedule[1].start, '2026-11-20T12:00:00+09:00');
  assert.equal(body.schedule[1].isOpenUse, true);
  assert.equal(body.recentReports[0].source, 'user_report');
  assert.equal(body.recentReports[0].reportedAt, '2026-11-20T03:00:00.000Z');
});

test('uses the Seoul date even when the UTC date differs', () => {
  // UTC 2026-11-20 16:00 = 서울 2026-11-21(토) 01:00 → 주말이라 시간표 없음
  const response = handleClassroomRequest('GET', '/classrooms/eng2-204', new Date('2026-11-20T16:00:00Z'));
  assert.deepEqual(JSON.parse(response.body).schedule, []);
});

test('routes classroom requests through the shared API handler', async () => {
  assert.equal((await request('GET', '/classrooms/eng2-204')).statusCode, 200);
  assert.equal((await request('GET', '/classrooms/unknown-room')).statusCode, 404);
  assert.equal((await request('POST', '/classrooms/eng2-204')).statusCode, 405);
});

test('keeps existing report routes unchanged', async () => {
  assert.equal((await request('GET', '/reports')).statusCode, 403);
  assert.equal((await request('GET', '/health')).statusCode, 200);
});
