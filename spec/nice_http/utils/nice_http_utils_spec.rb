require 'nice_http'

RSpec.describe NiceHttp, '#utils' do

  ##################################################
  # get a value of xml tag
  # input:
  #   tag_name
  #   xml_string
  #   take_off_prefix: boolean (optional). true, false(default)
  # output:
  #   the value or an array of all values found with this tag_name
  ####################################################
  #def self.get_value_xml_tag(tag_name, xml_string, take_off_prefix = false)
    
    it 'returns the value of the xml tag supplied' do
        xml = "<Example><One>Uno</One></Example>"
        val = NiceHttpUtils.get_value_xml_tag('One', xml)
        expect(val).to eq 'Uno'
    end

    it 'returns array of values of the xml tag supplied in case more than one tag with same name' do
        xml = "<Example><One>Uno</One><One>Unob</One></Example>"
        val = NiceHttpUtils.get_value_xml_tag('One', xml)
        expect(val).to eq ['Uno','Unob']
    end

    it 'returns the value of the xml tag supplied without taking in consideration prefix' do
        xml = "<bon:Example><bon:One>Uno</bon:One></bon:Example>"
        val = NiceHttpUtils.get_value_xml_tag('One', xml, true)
        expect(val).to eq 'Uno'
    end

    it 'returns nil if tag not found' do
        xml = "<Example><One>Uno</One><One>Unob</One></Example>"
        val = NiceHttpUtils.get_value_xml_tag('Dos', xml)
        expect(val).to eq nil
    end

    it 'sets the value for the xml tag supplied' do
        xml = "<Example><One>Uno</One></Example>"
        val = NiceHttpUtils.set_value_xml_tag('One', xml, 'Bob')
        expect(val).to eq '<Example><One>Bob</One></Example>'
    end

    it 'sets the value of the xml tag supplied without taking in consideration prefix' do
        xml = "<bon:Example><bon:One>Uno</bon:One></bon:Example>"
        val = NiceHttpUtils.set_value_xml_tag('One', xml, 'Bob', true)
        expect(val).to eq '<bon:Example><bon:One>Bob</bon:One></bon:Example>'
    end

    it 'returns same xml if not found tag to set' do
        xml = "<Example><One>Uno</One><One>Unob</One></Example>"
        val = NiceHttpUtils.set_value_xml_tag('Dos', xml, "Bob")
        expect(val).to eq xml
    end

    it 'return the correct enconding for basic authentication' do
        res = NiceHttpUtils.basic_authentication(user: "guest", password: "guest")
        expect(res).to eq "Basic Z3Vlc3Q6Z3Vlc3Q=\n"
    end


end
