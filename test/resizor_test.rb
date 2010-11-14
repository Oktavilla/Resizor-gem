require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class ResizorTest < Test::Unit::TestCase
  context 'When Resizor gem is not setup it' do
    setup do
      Resizor.instance_variable_set("@connection", nil)
    end

    ['get', 'post', 'delete'].each do |m|
      should "raise error for #{m}" do
        exception = assert_raise(RuntimeError) { Resizor.send(m, nil) }
        assert_equal 'Not connected. Please setup Resizor configuration first.', exception.message
      end
    end
  end

  context 'When Resizor gem has been setup it' do
    setup { setup_resizor }
    should 'return a API url' do
      assert_equal 'http://resizor.test:80', Resizor.api_url
    end
    
    should 'make a GET request to Resizor server with API key' do
      stub_http_request(:get, "resizor.test:80/assets.json?api_key=test-api-key").to_return(:body => '{"a": "123"}')
      Resizor.get('/assets.json').tap do |r|
        assert_equal 200, r.code
        assert_equal Hash['a', '123'], r.body
      end
    end

    should 'make a POST request to Resizor server with API key' do 
      stub_http_request(:post, "resizor.test:80/assets.json").with(:body => 'api_key=test-api-key').to_return(:body => '{"a": "123"}', :status => 201)
      Resizor.post('/assets.json').tap do |r|
        assert_equal 201, r.code
        assert_equal Hash['a', '123'], r.body
      end
    end

    should 'make a DELETE request to Resizor server with API key' do 
      stub_http_request(:delete, "resizor.test:80/assets/1.json?api_key=test-api-key")
      Resizor.delete('/assets/1.json').tap do |r|
        assert_equal 200, r.code
        assert_equal nil, r.body
      end
    end
    
    should 'add params along with API key when generating GET URL' do
      stub_http_request(:get, "resizor.test:80/assets.json?api_key=test-api-key&id=1")
      Resizor.get('/assets.json', :id => 1)
      assert_requested :get, "resizor.test:80/assets.json?api_key=test-api-key&id=1"
    end
   
    should 'add params along with API key when generating POST URL' do 
      stub_http_request(:post, "resizor.test:80/assets.json").with(:body => 'api_key=test-api-key&id=1')
      Resizor.post('/assets.json', :id => 1)
      assert_requested :post, "resizor.test:80/assets.json"
    end
 
    should 'add params along with API key when generating DELETE URL' do
      stub_http_request(:delete, "resizor.test:80/assets.json?api_key=test-api-key&id=1")
      Resizor.delete('/assets.json', :id => 1)
      assert_requested :delete, "resizor.test:80/assets.json?api_key=test-api-key&id=1"
    end

  end
end
