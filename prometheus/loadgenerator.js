import http from 'k6/http';
import { Httpx } from 'https://jslib.k6.io/httpx/0.0.4/index.js';
import { sleep,check} from 'k6';
import { Counter } from "k6/metrics";
//import tracing, { Http } from 'k6/x/tracing';
/**
 * Hipster workload generator by k6
 * @param __ENV.FRONTEND_ADDR
 * @constructor yuxiaoba
 */

let errors = new Counter("errors");




const baseurl = `http://${__ENV.FRONTEND_ADDR}`;
const host_header = `${__ENV.HOST_HEADER}`;

const waittime = [1,2,3,4,5,6,7,8,9,10]




export function setup() {
//  console.log(`Running xk6-distributed-tracing v${tracing.version}`);
}
export const options = {
    discardResponseBodies: true,
    vus: 5,
    duration: '5m',
};

export default function() {
   //  const http = new Http({
     //   exporter: "otlp",
       // propagator: "w3c",
         //endpoint: url
      //});
    //Access index page
    const session = new Httpx({
          baseURL: baseurl,
          timeout: 20000, // 20s timeout.
        });
    session.addHeader('Host', host_header);
    let res = session.get(`/`);
    let checkRes = check(res, { "status is 200": (r) => r.status === 200 });

    // show the error per second in grafana
    if (checkRes === false ){
        errors.add(1);
    }
    sleep(waittime[Math.floor(Math.random() * waittime.length)])


    //Access users page
    res = session.get(`/api/users`);
    checkRes = check(res, { "status is 200": (r) => r.status === 200 });

    // show the error per second in grafana
    if (checkRes === false ){
        errors.add(1);
    }
    sleep(waittime[Math.floor(Math.random() * waittime.length)])

    //register
    res = session.get(`/register`);
    checkRes = check(res, { "status is 200": (r) => r.status === 200 });

    // show the error per second in grafana
    if (checkRes === false ){
        errors.add(1);
    }
    sleep(waittime[Math.floor(Math.random() * waittime.length)])

    //Access login page

    res = session.get(`/login`);
    checkRes = check(res, { "status is 200": (r) => r.status === 200 });

    // show the error per second in grafana
    if (checkRes === false ){
        errors.add(1);
    }
    sleep(waittime[Math.floor(Math.random() * waittime.length)])

}

 export function teardown(){
      // Cleanly shutdown and flush telemetry when k6 exits.
     // tracing.shutdown();
    }