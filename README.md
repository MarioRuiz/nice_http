# NiceHttp

[![Gem Version](https://badge.fury.io/rb/nice_http.svg)](https://rubygems.org/gems/nice_http)

NiceHttp the simplest library for accessing and testing HTTP and REST resources.

Manage different hosts on the fly. Easily get the value you want from the JSON strings. Use hashes on your requests.

Also you can use mock responses by using :mock_response key on the request hash and enable the use_mocks option on NiceHttp.

NiceHttp will take care of the redirections and the cookies, and for security tests you will be able to modify the cookies or disable and control the redirections by yourself.

To be able to generate random requests take a look at the documentation for nice_hash gem: https://github.com/MarioRuiz/nice_hash

Example that creates 1000 good random and unique requests to register an user and test that the validation of the fields are correct by the user was able to be registered. Send 800 requests where just one field is wrong and verify the user was not able to be created: https://gist.github.com/MarioRuiz/824d7a462b62fd85f02c1a09455deefb

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
    data: {"name": "morpheus", "job": "leader"} 
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


You can specify all the defaults you will be using when creating connections by using the NiceHttp methods, in this example, http1 and http2 will be connecting to reqres.in and http3 to example.com:

```ruby

NiceHttp.host = 'reqres.in'
NiceHttp.ssl = true
NiceHttp.port = 443
NiceHttp.debug = false
NiceHttp.log = "./my_logs.log"

http1 = NiceHttp.new()

http2 = NiceHttp.new()

http3 = NiceHttp.new("https://example.com")

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


In case you want to modify the request before sending it, for example just changing one field but the rest will be the same, you can supply a new key :values in the request hash that will contain a hash with the keys to be changed and NiceHttp will perform the necessary changes at any level:

```ruby

req = Requests::Example.create_user_hash
req[:values] = {job: "developer"}

resp = http.post req

pp resp.data.json
#response: {:name=>"morpheus", :job=>"developer", :id=>"192", :createdAt=>"2018-12-14T14:41:54.371Z"}

```

## Responses

The response will include at least the keys:

*code*: the http code response, for example: 200

*message*: the http message response, for example: "OK"

*data*: the data response structure. In case of json we can get it as a hash by using: `resp.data.json`. Also you can filter the json structure and get what you want: `resp.data.json(:loginname, :address)`

Also interesting keys would be: *time_elapsed_total*, *time_elapsed* and many more available


## Special settings

*debug*: (true or false) it will set the connecition on debug mode so you will be able to see the whole communication with the server in detail

*log*: (:no, :screen, :file, :fix_file, "filename") it will log the basic communication for inspect. In case you want to add extra info to your logs you can do it for example adding to your code: http.logger.info "example extra log"

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


## Send multipart content

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

Bug reports and pull requests are welcome on GitHub at https://github.com/marioruiz/nice_http.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


