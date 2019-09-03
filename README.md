# NiceHttp

[![Gem Version](https://badge.fury.io/rb/nice_http.svg)](https://rubygems.org/gems/nice_http)
[![Build Status](https://travis-ci.com/MarioRuiz/nice_http.svg?branch=master)](https://github.com/MarioRuiz/nice_http)
[![Coverage Status](https://coveralls.io/repos/github/MarioRuiz/nice_http/badge.svg?branch=master)](https://coveralls.io/github/MarioRuiz/nice_http?branch=master)

NiceHttp the simplest library for accessing and testing HTTP and REST resources.

Manage different hosts on the fly. Easily get the value you want from the JSON strings. Use hashes on your requests. Get automatically statistics of your http communication and all the logs with the requests and responses.

Also you can use mock responses by using :mock_response key on the request hash and enable the use_mocks option on NiceHttp.

NiceHttp will take care of the redirections and the cookies, and for security tests you will be able to modify the cookies or disable and control the redirections by yourself.

NiceHttp is able to use hashes as requests data and uses the Request Hash structure: https://github.com/MarioRuiz/Request-Hash

**On the next link you have a full example using nice_http and RSpec to test REST APIs, Uber API and Reqres API: https://github.com/MarioRuiz/api-testing-example**

To be able to generate random requests take a look at the documentation for nice_hash gem: https://github.com/MarioRuiz/nice_hash

Example that creates 1000 good random and unique requests to register an user and test that the validation of the fields are correct by the user was able to be registered. Send 800 requests where just one field is wrong and verify the user was not able to be created: https://gist.github.com/MarioRuiz/824d7a462b62fd85f02c1a09455deefb

# Table of Contents

- [Installation](#Installation)
- [A very simple first example](#A-very-simple-first-example)
- [Create a connection](#Create-a-connection)
- [Creating requests](#Creating-requests)
- [Responses](#Responses)
- [Special settings](#Special-settings)
- [Authentication requests](#Authentication-requests)
- [Http logs](#Http-logs)
    - [Multithreading](#Multithreading)
- [Http stats](#Http-stats)
- [Tips](#Tips)
    - [Download a file](#Download-a-file)
    - [Send multipart content](#Send-multipart-content)
- [Contributing](#Contributing)
- [License](#License)

## Installation

Install it yourself as:

    $ gem install nice_http


## A very simple first example

```ruby
require 'nice_http'

http = NiceHttp.new('https://reqres.in')

resp = http.get("/api/users?page=2")

pp resp.code
pp resp.data.json

resp = http.get("/api/users/2")

pp resp.data.json(:first_name, :last_name)

resp = http.post( {
    path: "/api/users",
    data: { name: "morpheus", job: "leader" } 
} )

pp resp.data.json
```

## Create a connection

The simplest way is just by supplying the value as an argument:

```ruby

# as an url
http1 = NiceHttp.new("https://example.com")

# as parameters
http2 = NiceHttp.new( host: "reqres.in", port: 443, ssl: true )

# as a hash
http3 = NiceHttp.new my_reqres_server


```


You can specify all the defaults you will be using when creating connections by using the NiceHttp methods, in this example, http1 and http2 will be connecting to reqres.in with the default parameters and http3 to example.com:

```ruby

# default parameters
NiceHttp.host = 'reqres.in'
NiceHttp.ssl = true
NiceHttp.port = 443
NiceHttp.debug = false
NiceHttp.log = "./my_logs.log"
NiceHttp.headers = {"api-key": "the api key"}
NiceHttp.values_for = { region: 'europe', customerId: 334 }

http1 = NiceHttp.new()

http2 = NiceHttp.new()

http3 = NiceHttp.new("https://example.com")

```

If you prefer to supply a hash to change the default settings for NiceHttp:

```ruby
NiceHttp.defaults = {
    host: 'reqres.in',
    ssl: true,
    port: 443,
    debug: false,
    log: "./my_logs.log",
    headers: {"api-key": "the api key"}
}
```

To add a fixed path that would be added automatically to all your requests just before the specified request path, you can do it by adding it to `host`:

```ruby
http = NiceHttp.new('https://v2.namsor.com/NamSorAPIv2/')

resp = http.get('/api2/json/gender/Peter/Moon')
# The get request path will be: /NamSorAPIv2/api2/json/gender/Peter/Moon on server v2.namsor.com

resp = http.get('/api2/json/gender/Love/Sun?ret=true')
# The get request path will be: /NamSorAPIv2/api2/json/gender/Love/Sun on server v2.namsor.com
```

## Creating requests

You can use hash requests to simplify the management of your requests, for example creating a file specifying all the requests for your Customers API.

The keys you can use:

*path*: relative or absolute path, for example: "/api2/customers/update.do"

*headers*: specific headers for the request. It will include a hash with the values.

*data*: the data to be sent for example a JSON string. In case of supplying a Hash, Nice Http will assume that is a JSON and will convert it to a JSON string before sending the request and will add to the headers: 'Content-Type': 'application/json'

*mock_response*: In case of use_mocks=true then NiceHttp will return this response


Let's guess you have a file with this data for your requests on */requests/example.rb*:

```ruby

module Requests

  module Example
    
    # simple get request example
    def self.list_of_users()
        {
            path: "/api/users?page=2"
        }
    end

    # post request example using a request hash that will be converted automatically to a json string
    def self.create_user_hash()
        {
            path: "/api/users",
            data: { 
                name: "morpheus",
                job: "leader"
                }
        }
    end

    # post request example using a JSON string
    def self.create_user_raw()
        {
            path: "/api/users",
            headers: {"Content-Type": "application/json"},
            data: '{"name": "morpheus","job": "leader"}'
        }
    end

  end

end

```


Then in your code you can require this request file and use it like this:

```ruby

resp = http.get Requests::Example.list_of_users 

pp resp.code

resp = http.post Requests::Example.create_user_hash

pp resp.data.json


resp = http.post Requests::Example.create_user_raw

pp resp.data.json(:job)


```


In case you want to modify the request before sending it, for example just changing one field but the rest will be the same, you can supply a new key :values_for in the request hash that will contain a hash with the keys to be changed and NiceHttp will perform the necessary changes at any level:

```ruby

req = Requests::Example.create_user_hash
req.values_for = {job: "developer"}

resp = http.post req

pp resp.data.json
#response: {:name=>"morpheus", :job=>"developer", :id=>"192", :createdAt=>"2018-12-14T14:41:54.371Z"}

```

If the request hash contains a key :method with one of these possible values: :get, :head, :delete, :post or :patch, then it is possible to use the `send_request` method and pass just the request hash:

```ruby
     req= {
            path: "/api/users",
            method: :post,
            data: { 
                name: "morpheus",
                job: "leader"
            }
          }
     resp = @http.send_request req
```


## Responses

The response will include at least the keys:

*code*: the http code response, for example: 200

*message*: the http message response, for example: "OK"

*data*: the data response structure. In case of json we can get it as a hash by using: `resp.data.json`. Also you can filter the json structure and get what you want: `resp.data.json(:loginname, :address)`

Also interesting keys would be: *time_elapsed_total*, *time_elapsed* and many more available


## Special settings

*debug*: (true or false) it will set the connecition on debug mode so you will be able to see the whole communication with the server in detail

*log*: (:no, :screen, :file, :file_run, :fix_file, "filename") it will log the basic communication for inspect. In case you want to add extra info to your logs you can do it for example adding to your code: http.logger.info "example extra log"

*headers*: Hash containing the headers for the communication

*cookies*: Hash containing the cookies for the communication

*proxy_port, proxy_host*: in case you want to use a proxy for the connection

*use_mocks*: (true or false) in case of true if the request hash contains a mock_response key it will be returning that response instead of trying to send the request.

*auto_redirect*: (true or false) in case of true it will take care of the auto redirections.

## Authentication requests

All we need to do is to add to our request the correct authentication tokens, seeds, headers.

For example for Basic Authentication we need to add to the authorization header a seed generated with the user and password we want ot authenticate

```ruby

@http = NiceHttp.new("https://jigsaw.w3.org/")

@http.headers.authorization = NiceHttpUtils.basic_authentication(user: "guest", password: "guest")

# headers will be in this example: {:authorization=>"Basic Z3Vlc3Q6Z3Vlc3Q=\n"}

resp = @http.get("/HTTP/Basic/")

```

In case you want to use strict base64 use the option `strict: true`

Remember for other kind of authentication systems NiceHttp take care of the redirections and cookies that are requested to be set. In case you need to add a header with a token you can add it by using your NiceHttp object and the key headers, for example:

```ruby
@http.headers.tokenuno = "xxx"
# headers => {tokenuno: "xxx"}

#another way:
@http.headers[:tokendos] = "yyy"
# headers => {tokenuno: "xxx", tokendos: "yyyy"}

```

In case you want or need to control the redirections by yourself instead of allowing NiceHttp to do it, then set ```@http.auto_redirect = false```

An example using OpenID authentication:

```ruby
server = "https://samples.auth0.com/"
path="/authorize?client_id=kbyuFDidLLm280LIwVFiazOqjO3ty8KH&response_type=code"

@http = NiceHttp.new(server)

resp = @http.get(path)

p "With autoredirection:"
p "Cookies: "
p @http.cookies
p "Code: #{resp.code} #{resp.message} "
p "*"*40

@http2 = NiceHttp.new(server)
@http2.auto_redirect = false

resp = @http2.get(path)

p "Without autoredirection:"
p "Cookies: "
p @http2.cookies
p "Code: #{resp.code} #{resp.message} "

```

The output:

```
"With autoredirection:"
"Cookies: "
{"/"=>{"auth0"=>"s%3A6vEEwmmIf-9YAG-NjvsOIyZAh-NS97jj.yFSXILdmCov6DRwXjEei3q3eHIrxZxHI4eg4%2BTpUaK4"}, 
       "/usernamepassword/login"=>{"_csrf"=>"bboZ0koMScwXkISzWaAMTYdY"}}
"Code: 200 OK "
"****************************************"
"Without autoredirection:"
"Cookies: "
{"/"=>{"auth0"=>"s%3AcKndc44gllWyJv8FLztUIctuH4b__g0V.QEF3SOobK8%2FvX89iUKzGbfSP4Vt2bRtY2WH7ygBUkg4"}}
"Code: 302 Found "

```

You can see on the next link how to get the OAuth2 token for Microsoft Azure and add it to your Http connection header. 

https://gist.github.com/MarioRuiz/d3525185024737885c0c9afa6dc8b9e5

If you need a new token every time a new http connection is created you can use `lambda`

```ruby
NiceHttp.headers[:Authorization] = lambda {get_token()}
```

NiceHttp will call the get_token method you created every time a new Http connection is created.

## Http logs

You can set where the http logs will be stored by using the log attribute of the NiceHttp. 
By default they will be stored in your root directory with the name nice_http.log.
```ruby
    # you can specify the default for all connections
    NiceHttp.log = :file_run

    # also you can specify for a concrete connection
    http = NiceHttp.new({host: 'www.example.com', log: './example.log'})
```

Other values you can supply:
* :fix_file, will log the communication on nice_http.log. (default).
* :no, won't generate any logs.
* :screen, will print the logs on the screen.
* :file, will be generated a log file with name: nice_http_YY-mm-dd-HHMMSS.log.
* :file_run, will generate a log file with the name where the object was created and extension .log, fex: myfile.rb.log
* String, the path and file name where the logs will be stored.

Example of logs:
```
I, [2019-03-22T18:38:58.518964 #29412]  INFO -- : (47266856647720): Http connection created. host:reqres.in,  port:443,  ssl:true, mode:, proxy_host: , proxy_port:  
I, [2019-03-22T18:38:58.537106 #29412]  INFO -- : (47266856647720): Http connection: https://reqres.in:443


- - - - - - - - - - - - - - - - - - - - - - - - - 
POST Request: Doom.example
 path: /api/users
 headers: {Loop:44, Cookie:, Boom:33, Content-Type:application/json, }
 data: {
  "name": "peter",
  "job": "leader",
  "products": [
    {
      "one": "uno",
      "two": 2
    },
    {
      "one": "uno",
      "two": 22
    }
  ]
}

I, [2019-03-22T18:38:58.873935 #29412]  INFO -- : 
RESPONSE: 
 201:Created
 time_elapsed_total: '0.335720719'
 time_elapsed: '0.335728095'
 date: 'Fri, 22 Mar 2019 18:38:58 GMT'
 content-type: 'application/json; charset=utf-8'
 content-length: '172'
 connection: 'keep-alive'
 set-cookie: '__cfduid=dfb962e62cd8386ce4ab9bad601611553272738; expires=Sat, 21-Mar-20 18:38:58 GMT; path=/; domain=.reqres.in; HttpOnly'
 x-powered-by: 'Express'
 access-control-allow-origin: '*'
 etag: 'W/"ac-EMh4XBmK5vry/OeKaGWILGtmHU0"'
 expect-ct: 'max-age=604800, report-uri="https://report-uri.cloudflare.com/cdn-cgi/beacon/expect-ct"'
 server: 'cloudflare'
 cf-ray: '4bb99958090dbf89-AMS'
 data: '{
  "name": "peter",
  "job": "leader",
  "products": [
    {
      "one": "uno",
      "two": 2
    },
    {
      "one": "uno",
      "two": 22
    }
  ],
  "id": "628",
  "createdAt": "2019-03-22T18:43:33.619Z"
}'

I, [2019-03-22T18:38:58.874190 #29412]  INFO -- : set-cookie added to Cookie header as required
I, [2019-03-22T18:38:59.075293 #29412]  INFO -- : 

- - - - - - - - - - - - - - - - - - - - - - - - - 
GET Request: Doom.example
 path: /api/users
 Same headers and data as in the previous request.
I, [2019-03-22T18:38:59.403459 #29412]  INFO -- : 
RESPONSE: 
 200:OK
 time_elapsed_total: '0.327002338'
 time_elapsed: '0.327004766'
 date: 'Fri, 22 Mar 2019 18:38:59 GMT'
 content-type: 'application/json; charset=utf-8'
 transfer-encoding: 'chunked'
 connection: 'keep-alive'
 x-powered-by: 'Express'
 access-control-allow-origin: '*'
 etag: 'W/"1bb-D+c3sZ5g5u/nmLPQRl1uVo2heAo"'
 expect-ct: 'max-age=604800, report-uri="https://report-uri.cloudflare.com/cdn-cgi/beacon/expect-ct"'
 server: 'cloudflare'
 cf-ray: '4bb9995b5c20bf89-AMS'
 data: '{
  "page": 1,
  "per_page": 3,
  "total": 12,
  "total_pages": 4,
  "data": [
    {
      "id": 1,
      "first_name": "George",
      "last_name": "Bluth",
      "avatar": "https://s3.amazonaws.com/uifaces/faces/twitter/calebogden/128.jpg"
    },
    {
      "id": 2,
      "first_name": "Janet",
      "last_name": "Weaver",
      "avatar": "https://s3.amazonaws.com/uifaces/faces/twitter/josephstein/128.jpg"
    },
  ]
}'

```

### Multithreading

In case you want to use multithread and log in different files every thread, add an unique name for the thread then the logs will be stored accordingly

```ruby
require 'nice_http'

threads = []

40.times do |num|
    threads << Thread.new do
        Thread.current.name = num.to_s
        http = NiceHttp.new("https://reqres.in")
        request = {
          path: '/api/users',
          data: { name: 'morpheus', job: 'leader' },
        }
        http.post(request)
    end
end

t.each(&:join)

# log files: nice_http_0.log, nice_http_1.log... nice_http_39.log
```

## Http stats

If you want to get a summarize stats of your http communication you need to set `NiceHttp.create_stats = true` 

Then whenever you want to access the stats: `NiceHttp.stats` and if you want to save it on a file: `NiceHttp.save_stats`

After the run is finished the stats will automatically be saved even if you didn't call `save_stats`. The stats files will use the name and path on `NiceHttp.log`.

If you are using RSpec and you want to generate the stats files after every test is finished, add to your spec_helper.rb file:

```ruby
RSpec.configure do |config|
  config.after(:each) do
    NiceHttp.save_stats
  end
end
```

This is an example of the output:

```yaml
---
reqres.in:443:
  :num_requests: 11
  :time_elapsed:
    :total: 2.947269038
    :maximum: 0.357101109
    :minimum: 0.198707111
    :average: 0.2679335489090909
  "/api/users":
    :num_requests: 11
    :time_elapsed:
      :total: 2.947269038
      :maximum: 0.357101109
      :minimum: 0.198707111
      :average: 0.2679335489090909
    :method:
      POST:
        :num_requests: 8
        :time_elapsed:
          :total: 2.3342455970000002
          :maximum: 0.357101109
          :minimum: 0.198707111
          :average: 0.29178069962500003
        :response:
          '201':
            :num_requests: 8
            :time_elapsed:
              :total: 2.3342455970000002
              :maximum: 0.357101109
              :minimum: 0.198707111
              :average: 0.29178069962500003
      GET:
        :num_requests: 3
        :time_elapsed:
          :total: 0.613023441
          :maximum: 0.210662528
          :minimum: 0.200197583
          :average: 0.20434114699999997
        :response:
          '200':
            :num_requests: 3
            :time_elapsed:
              :total: 0.613023441
              :maximum: 0.210662528
              :minimum: 0.200197583
              :average: 0.20434114699999997
```

If you want to add specific stats for your processes you can use the method `NiceHttp.add_stats`

```ruby
   # random customer name
   customer_name = "10-20:L".gen
   started = Time.now
   @http.send_request Requests::Customer.add_customer(name: customer_name)
   30.times do
      resp = @http.get(Requests::Customer.get_customer(name: customer_name))
      break if resp.code == 200
      sleep 0.5
   end
   NiceHttp.add_stats(:customer, :create, started, Time.now)
```

To add the items for every specific stats to be accessed as an array you can add it as the last parameter of `add_stats`
```ruby
NiceHttp.add_stats(:customer, :create, started, Time.now, customer_name)
```

This will generate an items key that will contain an array of the values you added.

## Tips

### Download a file

* Direct download:

```ruby
resp = NiceHttp.new("https://euruko2019.org").get("/assets/images/logo.png", save_data: './tmp/')
```

* Get the data and store it like you want:

```ruby
resp = NiceHttp.new("https://euruko2019.org").get("/assets/images/logo.png")
File.open('./logo.png', 'wb') { |fp| fp.write(resp.data) }
```

### Send multipart content

Example posting a csv file:

```ruby

	require 'net/http/post/multipart'
	request = {
		path: "/customer/profile/",
		headers: {'Content-Type' => 'multipart/form-data'},
		data: (Net::HTTP::Post::Multipart.new "/customer/profile/",
		  "file" => UploadIO.new("./path/to/my/file.csv", "text/csv"))
	}
	response=@http.post(request)

```


## Contributing

Bug reports are very welcome on GitHub at https://github.com/marioruiz/nice_http.

If you want to contribute please follow [GitHub Flow](https://guides.github.com/introduction/flow/index.html)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
