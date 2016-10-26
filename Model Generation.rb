require 'green_shoes'
require 'csv'
require 'benchmark'

unique_arr = Array.new
unique_str_arr = Array.new
unique_index = Array.new
temp_row = Array.new

ACCEPTANCE = 0.015	#Define STD maximum value for acceptance.

class String
	def valid_float?
		true if Float self rescue false
	end
end

temp_file = ask_open_file("")
association_arr = CSV.read(temp_file)

association_arr.delete_at(0)


#*********************************************************************************************
#*			       			  	Filter tags to system codes.						    	 *
#*********************************************************************************************
name_index = association_arr.map{|x| x[0].dup}
name_index.each do |row|	#Create array of tags stripped back to system level.
	temp = row.dup.split("_", 5)
	temp.pop
	unique_index << temp.join("_")
end
#name_index.each do |row|
#	holding_arr = row.dup.split("_")
#	unique_arr << holding_arr.dup.map{ |s| s.to_s =~ /\d/ || s.length == 1 ? "::" : s }
#end
#unique_arr.map!{ |x| x.join("_")}.flatten


association_arr.map! do |temp_row|	#Typecast to floats or invalid delimiters.
	temp_row.map{ |x| x.valid_float? ? x.to_f : 111.111 }
end

puts "Compiling Models..."
association_arr.each_with_index do |row, idr|
	row.delete_at(0)
	temp_row = row.each_with_index.map{ |x, idx| x.to_f <= ACCEPTANCE &&  
		unique_index[idr].to_s == unique_index[idx].to_s && 
		name_index[idx] != nil ? name_index[idx] + ": " + x.round(3).to_s : nil}.compact.dup.flatten

	if temp_row.length > 2
		row.each_with_index{ |x, idx| x.to_f <= ACCEPTANCE && unique_index[idr].to_s == unique_index[idx].to_s ? name_index[idx] = nil : x}
	end
	
	temp_row.sort!{ |x, y| x[x.length - 5..x.length] <=> y[y.length - 5..y.length] }

	if temp_row.length > 2 then
		CSV.open(temp_file[0...-4] + " Model_Groups.csv", 'ab') do |csv|
			csv << temp_row.flatten
		end
	end
end