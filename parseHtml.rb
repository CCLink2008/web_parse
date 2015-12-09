require 'nokogiri'
require 'open-uri'
require 'uri'
require "csv"

# category 0
# * company name 1
# * street address  2
# * street address 2  3
# * city  4
# * state 5
# * postal code 6
# * phone number 7 
# * contact salutation 8
# * contact first name 9
# * contact last name 10
# * contact credentials 11 (e.g., CPA, MD, MBA, etc - put stuff like JR here too)
# * member since (year) 12
# * company website address (the URL from "visit site") 13
# * facebook link 14
# * twitter link 15
# * linkedin link 16
# * youtube link  17
# * google plus link 18
# * pinterest link 19 
# * instagram link  20 
# * foursquare link  21

 
def getHeader()
myar =  ["category",
 "company name",
 "street address",
 "street address 2",
 "city",
 "state",
 "postal code",
 "phone number",
 "contact salutation",
 "contact first name",
 "contact last name",
 "contact credentials",
 "member since (year)",
 "company website address",
 "facebook ",
 "twitter ",
 "linkedin ",
 "youtube ",
 "google plus ",
 "pinterest ",
 "instagram ",
 "foursquare "]
end  


def parseHtml(url)
	tryies = 0 
    items = []
	begin
	   tryies+=1 
	   subpage = Nokogiri::HTML(open(url))

	   subpage.css(GetName(1,"CONTAINER")).each do |sub_div|
	     items.push(parse_item(sub_div,1))  
	   end
     subpage.css(GetName(5,"CONTAINER")).each do |sub_div|
       items.push(parse_item(sub_div,5)) 
     end
	  	
	rescue OpenURI::HTTPError => e
		if (tryies<5)
			sleep(2**tryies)
			retry
		end
	end
    return items  
end

def parse_item(item,type)
   tmp_name = item.css(GetName(type,"HEADER")).css("span")
   a_item = []
   # company name 1
   if tmp_name.attribute("itemprop").to_s == "name"
   	 a_item[1] = tmp_name.text
   end  

   tmp_main = item.css(GetName(type,"MAINLEFTBOX")).children 
   tmp_main.each do |m_item|
   	  m_attr = m_item.attribute("itemprop").to_s
   	  m_txt = m_item.text
      # street address  2
      if  m_attr == "street-address"
        a_item[2] =  m_txt
      end
      #  city  4
      if m_attr == "locality"
        a_item[4] =  m_txt   
      end
      #  state 5
      if m_attr == "region"
        a_item[5] =  m_txt  
      end
      #  postal code 6
      if m_attr == "postal-code"
        a_item[6] =  m_txt    
      end
      if m_item.attribute("class")
          md_attr = m_item.attribute("class").to_s 
          # * phone number 7             
          a_item[7]  =  m_txt  if md_attr.include? "PHONE1"
          # contact  8
          a_item[8]  =  m_txt if md_attr.include? "MAINCONTACT"
          # member since (year) 12
          a_item[12] =  m_txt.split(":")[1]  if md_attr.include? "MEMBERSINCE"              	       
       end     
   end 
   # visit site 
   tmp_site = item.css(GetName(type,"VISITSITE")) 
   #  company website address 
   if tmp_site.children[1]!=nil
        c_site = URI.unescape(tmp_site.children[1].attribute("href").to_s) if tmp_site.children[1].attribute("href")!=nil
     	a_item[13] = c_site     	
   end

   ## footer social media 
   tmp_foot = item.css(GetName(type,"SOCIALMEDIA")).children 
    tmp_foot.each do |f|
    	url = f.attribute('href')
     	if url 
     	   url = URI.unescape(url.to_s.split("?")[1][4..-1]) 
     	   w_name = f.children.attribute("alt").to_s.downcase 
     	   #  facebook link 14
         #  twitter link 15
         #  linkedin link 16
         #  youtube link  17
         #  google plus link 18
         #  pinterest link 19 
         #  instagram link  20 
         #  foursquare link  21
         if w_name.include? "facebook"  
            a_item[14] =   url
     	   elsif w_name.include? "twitter"
     	      a_item[15] =   url   
         elsif w_name.include? "linkedin"
           	a_item[16] =   url
         elsif w_name.include? "youtube"
           	a_item[17] =   url
         elsif w_name.include? "google"
           	a_item[18] =   url
         elsif  w_name.include? "pinterest"
            a_item[19] =   url
         elsif w_name.include? "instagram"
            a_item[20] =   url
         elsif w_name.include? "foursquare"
            a_item[21] =   url			
     	   end  	 
        end 
    end
    a_item   
end

def GetName(level,position)
	str= ".ListingResults_Level#{level}_#{position}"
end



def generateCsv(url)

  page = Nokogiri::HTML(open("#{url}/allcategories"))
  
  name  = Time.now.year.to_s+'-'+ Time.now.month.to_s+'-'+Time.now.day.to_s+'--'+Time.now.hour.to_s+'-'+Time.now.min.to_s+'-'+Time.now.sec.to_s
  CSV.open("#{name}.csv", "wb") do |csv|
    csv << getHeader()    
     page.css('.ListingCategories_AllCategories_CATEGORY').each do |item|
       sub_url = url +  item.at_css('a')[:href]      
       csv << ["#{item.at_css('a')[:href][1..-1]}"] 
       cm_arr = parseHtml(sub_url)      
       cm_arr.each do  |item|
 			csv << item 
      end
     end
  end
end


url = "http://www.cobbchamber.org"
generateCsv(url)
