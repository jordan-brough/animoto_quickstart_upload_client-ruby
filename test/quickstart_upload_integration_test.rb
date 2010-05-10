require 'test/unit'
require 'rubygems'
require 'quickstart_upload_client'

class QuickstartUploadClientIntegrationTest < Test::Unit::TestCase
  AFFILIATE_REFERRAL_CODE = 'a_ogkyselc'
  SECRET_KEY = '6c3d8cdee6'

  def setup
    # param 1 - affiliate referral code
    # param 2 - quickstart upload secret key
    @client = Animoto::QuickstartUploadClient.new(AFFILIATE_REFERRAL_CODE, SECRET_KEY)
  end

  def test_generate_signature
    signature = client.generate_signature(:client_id => 'test', :n => 3, :type => 'gif')
    assert signature
  end

  def test_get_resource_links
    links = client.get_resource_links("jpg", 5)
    assert_equal 5, links.size
    links.each do |link|
      assert_match /(\d)\.jpg/, link
      assert_match /#{AFFILIATE_REFERRAL_CODE}/, link
    end
  end

  def test_get_resource_links_invalid_secret_key
    e = assert_raise Animoto::HttpError do
      Animoto::QuickstartUploadClient.new('a_ogkyselc', 'bad_key').get_resource_links("jpg", 5)
    end
    assert e
    assert_equal 401, e.code
  end

  def test_get_resource_links_invalid_referral_code
    e = assert_raise Animoto::HttpError do 
      Animoto::QuickstartUploadClient.new('bad_code', '6c3d8cdee6').get_resource_links("jpg", 5)
    end
    assert e
    assert_equal 401, e.code
  end

  def test_get_resource_links_invalid_media_type
    e = assert_raise Animoto::HttpError do
      client.get_resource_links("doh", 5)
    end 
    assert e
    assert_equal 415, e.code
  end

  def test_get_resource_links_with_client_id
    links = client.get_resource_links("jpg", 3, 'id_of_your_customer')
    assert_equal 3, links.size
    links.each do |link|
      assert_match /id_of_your_customer/, link
      assert_match /(\d)\.jpg/, link
      assert_match /#{AFFILIATE_REFERRAL_CODE}/, link
    end
  end

  protected

  def client
    @client
  end
end
