module NiceHttpUtils

  ##################################################
  # set a value on xml tag
  # @param tag_name [String]
  # @param xml_string [String]
  # @param value [String]
  # @param take_off_prefix [Boolean] (optional). true, false(default)
  # @return [String] with the new value
  ####################################################
  def self.set_value_xml_tag(tag_name, xml_string, value, take_off_prefix = false)
    tag_name = tag_name.to_s
    if take_off_prefix
      i = tag_name.index(":")
      tag_name = tag_name[i + 1..tag_name.length] unless i.nil?
    end
    if xml_string.to_s != ""
      if take_off_prefix
        old_value = NiceHttpUtils.get_value_xml_tag(tag_name, xml_string.dup, true)
        xml_string.gsub!(/:#{tag_name}>#{Regexp.escape(old_value)}<\//i, ":" + tag_name + ">" + value + "</")
        xml_string.gsub!(/<#{tag_name}>#{Regexp.escape(old_value)}<\//i, "<" + tag_name + ">" + value + "</")
      else
        xml_string.gsub!(/<#{tag_name}>.*<\/#{tag_name}>/i, "<" + tag_name + ">" + value + "</" + tag_name + ">")
      end
      return xml_string
    else
      return ""
    end
  end
end
