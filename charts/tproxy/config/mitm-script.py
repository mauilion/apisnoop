from mitmproxy import http
from mitmproxy.script import concurrent
import re
import os
import requests
import threading
import queue

WEBHOOK = "http://audit.ii.nz:9901"

send_queue = queue.Queue()

def send_thread_run(*args, **kwargs):

    while True:
        payload = send_queue.get()
        print("Sending payload:", str(payload))
        try:
            requests.post(WEBHOOK, data=payload)
        except e:
            print("Error sending to webhook: ", e)
        send_queue.task_done()

def load(l):
    # start thread
    t = threading.Thread(target=send_thread_run, daemon=True)
    t.start()

def request(flow: http.HTTPFlow) -> None:
    # content_type = flow.request.headers.get("Content-Type")
    # if content_type and content_type != "application/json":
    #     print("skipping non-json request:", content_type)
    #     return
    try:
        payload = {
            "request_data": flow.request.content,
            "timestamp": flow.request.timestamp_start,
            #"status_code": flow.response.status_code,
            "url": flow.request.pretty_url,
            "method": flow.request.method,
            "sender_ip": flow.client_conn.address,
        }
    except e:
        print("Error: ", e)
        return

    send_queue.put(payload)
