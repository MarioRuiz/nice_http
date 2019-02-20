require 'nice_http'

RSpec.describe NiceHttp, '#post' do

    before do
        @http = NiceHttp.new('https://www.reqres.in')
    end
    
    it 'accepts hash including keys :data and :path' do
        resp = @http.post( {
            path: "/api/users",
            data: { name: "morpheus", job: "leader" } 
        } )
        expect(resp.code).to eq 201
    end

    it 'accepts parameters as array of path, data, headers' do
        resp = @http.post( "/api/users", "{ 'name': 'morpheus', 'job': 'leader' }", {} )
        expect(resp.code).to eq 201
    end

    it 'returns error in case no path' do
        resp = @http.post({data: { name: "morpheus", job: "leader" }})
        expect(resp.class).to eq Hash
        expect(resp.fatal_error).to match /no[\w\s]+path/i
        expect(resp.code).to eq nil
        expect(resp.message).to eq nil
        expect(resp.data).to eq nil
    end

    it 'accepts data_examples array in case no data supplied' do
        resp = @http.post( {
            path: "/api/users",
            data_examples: [{ name: "doopy", job: "loope" }] 
        } )
        expect(resp.code).to eq 201
        expect(resp.data.json(:name)).to eq 'doopy'
    end
    
    it 'returns the mock response if specified' do
        @http.use_mocks = true
        request = {
            path: "/api/users",
            data: { name: "morpheus", job: "leader" },
            mock_response: {
                code: 100,
                message: "mock",
                data: { example: "mock" }
            }
        }
        resp = @http.post(request)
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 100
        expect(resp.message).to eq 'mock'    
        expect(resp.data.json).to eq ({ example: "mock" }) 
     end
    
    it 'changes :data when supplied :values_for' do
        request = {
            path: "/api/users",
            data: { name: "morpheus", job: "leader" } 
        }

        request.values_for = {name: "peter"}
        resp = @http.post(request)
        expect(resp.code).to eq 201
        expect(resp.data.json(:name)).to eq 'peter'
    end

    it 'redirects when auto_redirect is true and http code is 30x' do
        server = "http://examplesinatra--tcblues.repl.co/"
        http = NiceHttp.new(server)
        http.auto_redirect = true
        req = {
            path: '/exampleRedirect',
            data: {example: 'example'},
        }
        resp = http.post(req)
        expect(resp.code).to eq 200
        expect(resp.message).to eq 'OK'
    end

    it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
        server = "http://examplesinatra--tcblues.repl.co/"
        http = NiceHttp.new(server)
        http.auto_redirect = false
        req = {
            path: '/exampleRedirect',
            data: {example: 'example'},
        }
        resp = http.post(req)
        expect(resp.code).to eq 303
    end

    it 'accepts all kind of Content-Type' do
        # as symbol
        req = {
            path: "/api/users",
            headers: {"Content-Type": "application/json"},
            data: '{"name": "morpheus","job": "leader"}'
        }

        # as symbol
        resp = @http.post req
        expect(NiceHttp.last_request).to match /Content-Type:application\/json/
        
        req.headers = {"content-type": "application/json"}
        resp = @http.post req
        expect(NiceHttp.last_request).to match /Content-Type:application\/json/
        
        # as string
        req.headers = {"content-type"=>"application/json"}
        resp = @http.post req
        expect(NiceHttp.last_request).to match /Content-Type:application\/json/

        # as string
        req.headers = {"Content-Type"=> "application/json"}
        resp = @http.post req
        expect(NiceHttp.last_request).to match /Content-Type:application\/json/
    end

    it 'implements json data by default if no content type supplied and a hash for data' do
        req = {
            path: "/api/users",
            data: { name: "morpheus",job: "leader"}
        }
    
        # not supplied content type by default
        resp = @http.post req
        expect(NiceHttp.last_request).to match /Content-Type:application\/json/
    
    end

    it 'changes data to empty string if data is nil' do
        req = {
            path: "/api/users",
            data: nil
        }
        resp = @http.post req
        expect(NiceHttp.last_request).to match /data=\s*$/
    end

    it 'accepts values as an alias for values_for' do
        request = {
            path: "/api/users",
            data: { name: "morpheus", job: "leader" } 
        }

        request[:values] = {name: "peter"}
        resp = @http.post(request)
        expect(resp.code).to eq 201
        expect(resp.data.json(:name)).to eq 'peter'
    end

    it 'change xml value when supplied values_for' do
        request = {
            path: "/api/users",
            headers: {"Content-Type": "text/xml"},
            data: "<name>morpheus</name><job>leader</job>"
        }

        request.values_for = {name: "peter"}
        resp = @http.post(request)
        expect(NiceHttp.last_request).to match /name>peter/
    end

    it 'changes json string values when values_for supplied and json is a string' do
        request = {
            path: "/api/users",
            headers: {"Content-Type": "application/json"},
            data: '{"name": "morpheus","job": "leader"}'
        }
        request.values_for = {name: "peter"}
        resp = @http.post(request)
        expect(NiceHttp.last_request).to match /"name": "peter"/
    end

    it 'accepts an array as data' do
        request = {
            path: "/api/users",
            headers: {"Content-Type": "application/json"},
            data: [
                {name: 'morpheus', job: 'leader'},
                {name: 'peter', job: 'vicepresident'}
            ]
        }
        resp = @http.post(request)
        expect(resp.code).to eq 201
        expect(resp.data.json(:name)).to eq ['morpheus','peter']
    end

    it 'changes all values on array request when values_for' do
        request = {
            path: "/api/users",
            headers: {"Content-Type": "application/json"},
            data: [
                {name: 'morpheus', job: 'leader'},
                {name: 'peter', job: 'vicepresident'}
            ]
        }
        request.values_for = {job: ['dev','cleaner']}
        resp = @http.post(request)
        expect(resp.code).to eq 201
        expect(resp.data.json(:job)).to eq ['dev','cleaner']
    end

    #todo: add tests encoding and cookies

end
