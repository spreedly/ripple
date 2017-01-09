require 'riak_test_server'

TEST_SERVER_HTTP_PORT = 17017
TEST_SERVER_PB_PORT = 17018

RSpec.configure do |config|
  config.before(:each, integration: true) do
    Ripple.config = {
      nodes: [
        {
          host: "localhost",
          http_port: TEST_SERVER_HTTP_PORT,
          pb_port: TEST_SERVER_PB_PORT
        }
      ]
    }
  end
end
