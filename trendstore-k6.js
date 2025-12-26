import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 10, // concurrent users
  duration: "2m", // total test time
};

const BASE_URL = "http://192.168.58.2:30080"; // your app URL from Windows browser

export default function () {
  const res = http.get(BASE_URL);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(0.1);
}
