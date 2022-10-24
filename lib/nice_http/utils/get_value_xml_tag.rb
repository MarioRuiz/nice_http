module NiceHttpUtils
  ##################################################
  # get a value of xml tag
  # @param tag_name [String]
  # @param xml_string [String]
  # @param take_off_prefix [Boolean] (optional). true, false(default)
  # @return [String, Array] the value or an array of all values found with this tag_name
  ####################################################
  def self.get_value_xml_tag(tag_name, xml_string, take_off_prefix = false)
    return nil if xml_string.nil?
    xml_string2 = xml_string.dup()
    if take_off_prefix
      i = tag_name.index(":")
      if !i.nil?
        tag_name = tag_name[i + 1..tag_name.length]
      end
    end

    ret = Array.new()
    if xml_string2.to_s() != ""
      if take_off_prefix
        xml_string2.gsub!(/<[a-zA-Z0-9]+:#{tag_name} [^>]*>/i, "<" + tag_name + ">")
        xml_string2.gsub!(/<\/[a-zA-Z0-9]+:#{tag_name}>/i, "</" + tag_name + ">")
        xml_string2.gsub!(/<[a-zA-Z0-9]+:#{tag_name}>/i, "<" + tag_name + ">")
      end

      xml_string2.gsub!(/<#{tag_name} [^>]*>/i, "<" + tag_name + ">")

      tag1 = "<" + tag_name + ">"
      tag2 = "</" + tag_name + ">"

      x = xml_string2.index(tag1)
      if !x.nil?
        x += tag1.size
        begin
          y = xml_string2.index(tag2)
          if y.nil?
            ret.push("")
            x = nil
          else
            y -= 1
            value = xml_string2[x..y]
            ret.push(value)
            xml_string2 = xml_string2[y + tag2.size..xml_string2.length]
            x = xml_string2.index(tag1)
            if !x.nil?
              x += tag1.size
            end
          end
        end while !x.nil?
      else
        ret.push("")
      end
    else
      ret.push("")
    end
    if ret.size == 1
      return ret[0].to_s()
    else
      return ret
    end
  end
end
