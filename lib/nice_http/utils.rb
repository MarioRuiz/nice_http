module NiceHttpUtils
    ##################################################
    # get a value of xml tag
    # input:
    #   tag_name
    #   xml_string
    #   take_off_prefix: boolean (optional). true, false(default)
    # output:
    #   the value or an array of all values found with this tag_name
    ####################################################
    def self.get_value_xml_tag(tag_name, xml_string, take_off_prefix=false)
      return nil if xml_string.nil?
      xml_string2=xml_string.dup()
      if take_off_prefix then
        i=tag_name.index(":")
        if !i.nil? then
          tag_name=tag_name[i+1..tag_name.length]
        end
      end

      ret=Array.new()
      if xml_string2.to_s()!="" then

        if take_off_prefix then
          xml_string2.gsub!(/<[a-zA-Z0-9]+:#{tag_name} [^>]*>/i, "<" + tag_name + ">")
          xml_string2.gsub!(/<\/[a-zA-Z0-9]+:#{tag_name}>/i, "</" + tag_name + ">")
          xml_string2.gsub!(/<[a-zA-Z0-9]+:#{tag_name}>/i, "<" + tag_name + ">")
        end

        xml_string2.gsub!(/<#{tag_name} [^>]*>/i, "<" + tag_name + ">")

        tag1="<" + tag_name + ">"
        tag2="</" + tag_name + ">"

        x=xml_string2.index(tag1)
        if !x.nil? then
          x+=tag1.size
          begin
            y=xml_string2.index(tag2)
            if y.nil? then
              ret.push("")
              x=nil
            else
              y-=1
              value=xml_string2[x..y]
              ret.push(value)
              xml_string2=xml_string2[y+tag2.size..xml_string2.length]
              x=xml_string2.index(tag1)
              if !x.nil? then
                x+=tag1.size
              end
            end
          end while !x.nil?
        else
          ret.push("")
        end
      else
        ret.push("")
      end
      if ret.size==1 then
        return ret[0].to_s()
      else
        return ret
      end
    end


  ##################################################
  # set a value on xml tag
  # input:
  #   tag_name
  #   xml_string
  #   value
  #   take_off_prefix: boolean (optional). true, false(default)
  # output:
  #   xml_string with the new value
  ####################################################
  def self.set_value_xml_tag(tag_name, xml_string, value, take_off_prefix = false)
    tag_name = tag_name.to_s
    if take_off_prefix
      i = tag_name.index(':')
      tag_name = tag_name[i + 1..tag_name.length] unless i.nil?
    end
    if xml_string.to_s != ''
      if take_off_prefix
        old_value = NiceHttpUtils.get_value_xml_tag(tag_name, xml_string.dup, true)
        xml_string.gsub!(/:#{tag_name}>#{Regexp.escape(old_value)}<\//i, ':' + tag_name + '>' + value + '</')
        xml_string.gsub!(/<#{tag_name}>#{Regexp.escape(old_value)}<\//i, '<' + tag_name + '>' + value + '</')
      else
        xml_string.gsub!(/<#{tag_name}>.*<\/#{tag_name}>/i, '<' + tag_name + '>' + value + '</' + tag_name + '>')
      end
      return xml_string
    else
      return ''
    end
  end  

  ##################################################
  # returns the seed for Basic authentication
  # input:
  #   user
  #   password
  # output:
  #   seed string to be used on Authorization key header on a get request
  ####################################################
  def self.basic_authentication(user: , password: )
    require 'base64'
    seed = "Basic " + Base64.encode64(user + ":" + password)
    return seed
  end

end