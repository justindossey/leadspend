leadspend
=========

Ruby library for communicating with the Leadspend service


Use like so:
```ruby
  client = Leadspend::Client.new(:username => LEADSPEND_USERNAME, :password => LEADSPEND_PASSWORD, 
      :ca_file => CA_FILE, :timeout => 5)
  is_valid_email = client.validate(params[:email) # true if verified or unknown, false otherwise
```
If you want more information about the response, use something like

```ruby
  leadspend_result = client.fetch_result(params[:email])
```
This will return a Leadspend::Result object representing the JSON response,
with convenience methods like unreachable? and illegitimate?.

Written by Justin Dossey for PodOmatic, www.podomatic.com, jbd@podomatic.com.

Project homepage: http://www.github.com/justindossey/leadspend

