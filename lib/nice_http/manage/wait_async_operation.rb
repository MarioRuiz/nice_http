module NiceHttpManageResponse
  def wait_async_operation(response: @response, async_wait_seconds: @async_wait_seconds, async_header: @async_header, async_completed: @async_completed, async_resource: @async_resource, async_status: @async_status)
    resp_orig = response.deep_copy
    if async_wait_seconds.to_i > 0 and !async_header.empty? and !async_completed.empty?
      if response.code == 202 and response.key?(async_header.to_sym)
        begin
          location = response[async_header.to_sym]
          time_elapsed = 0
          resp_async = {body: ''}
          while time_elapsed <= async_wait_seconds
            path, data, headers_t = manage_request({ path: location })
            resp_async = @http.get path
            completed = resp_async.body.json(async_completed.to_sym)
            break if completed.to_i == 100 or time_elapsed >= async_wait_seconds
            time_elapsed += 1
            sleep 1
          end
          resp_orig.async = {}
          resp_orig.async.seconds = time_elapsed
          resp_orig.async.data = resp_async.body
          if resp_async.body.json.key?(async_status.to_sym)
            resp_orig.async.status = resp_async.body.json(async_status.to_sym) 
          else
            resp_orig.async.status = ''
          end
          unless async_resource.empty?
            location = resp_async.body.json(async_resource.to_sym)
            if location.empty?
                resp_orig.async.resource = {}
            else
              path, data, headers_t = manage_request({ path: location })
              resp_async = @http.get path
              resp_orig.async.resource = {data: resp_async.body}
            end
          end
        rescue Exception => stack
          @logger.warn stack
        end
      end
    end
    return resp_orig
  end
end
