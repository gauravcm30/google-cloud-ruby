# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "trace_helper"

describe Google::Cloud::Trace, :trace do
  it "automatically creates trace for a ingress request" do
    send_request "test_trace"

    # Wait 60 seconds before querying for the trace record
    sleep 60

    results = nil
    keep_trying_till_true 240 do
      result_set = @tracer.list_traces Time.now - 300, Time.now, filter: "root:/test_trace"
      results = result_set.instance_variable_get :@results
      !results.empty?
    end

    results.wont_be_empty
  end

  it "allows custom spans with custom labels" do
    token = rand(0x100000000000).to_s
    send_request "test_trace", "token=#{token}"

    # Wait 60 seconds before querying for the trace record
    sleep 60

    results = nil
    keep_trying_till_true 60 do
      result_set = @tracer.list_traces Time.now - 300, Time.now, filter: "span:integration_test_span", view: :COMPLETE
      results = result_set.instance_variable_get :@results
      !results.empty?
    end

    results.wont_be_empty

    results.each do |trace_record|
      trace_record.all_spans.wont_be_empty
      trace_record.all_spans.each do |span|
        span.labels["token"].must_equal token if span.name == "integration_test_span"
      end
    end
  end
end
