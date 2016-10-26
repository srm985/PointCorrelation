require 'green_shoes'
require 'csv'
require 'benchmark'
require 'parallel'


#*********************************************************************************************
#*								 Determine if string is numeric.							 *
#*********************************************************************************************
class string	#Function used for type checking.
	def valid_float?
		true if Float self rescue false
	end
end

def calcSTD(row_1, row_2)	#Function used to determine tag-to-tag deviation.
	temp_row = Array.new
	row_1.each_with_index do |x, idx|
		y = row_2[idx]
		#unless x == 111.111 || y == 111.111
		unless x > 1 || y > 1
			temp_row << (x - y).abs
		end
	end
	temp_row
end

def calcVAR(temp_row, temp_len, temp_AVG)	#Function used for final variance calculation.
	temp_VAR = 0
	temp_row.each do |x|
		temp_VAR += (x - temp_AVG)**2
	end
	temp_VAR / temp_len
end

def calcVAR_Init(temp_row, temp_len, temp_AVG)	#Function used for flatline filtering.
	temp_VAR = 0
	temp_row.each do |x|
		unless(x > 1)
			temp_VAR += (x - temp_AVG)**2
		end
	end
	temp_VAR / temp_len
end


puts "Parsing..."
#*********************************************************************************************
#*			       				Materialize variables and constants.				    	 *
#*********************************************************************************************
FLATLINE_STD = 0	#Define when a signal is considered flat lined.
step_arr = Array.new
step_arr.clear
holding_step_arr = Array.new
signalSTD_arr = Array.new

temp_file = ask_open_file("")
temp_arr = CSV.read(temp_file)

name_index = temp_arr.map{|x| x[0].dup}

temp_arr.each do |temp_row|

#*********************************************************************************************
#*			       			Set up temporary array of only valid data.				    	 *
#*********************************************************************************************
	temp_row.pop	#Remove last point as it's nil.
	holding_row = temp_row.reject{ |x| !x.valid_float? }.dup	#Prune array.
	holding_row.map!{ |x| x.to_f}	#Typecast to floats.
	arr_sort = holding_row.sort 	#Temporarily sort array to extract max and min values for normalization.


#*********************************************************************************************
#*			       		Grab statistical values needed for calculations.			    	 *
#*********************************************************************************************
	temp_MIN = arr_sort[0].to_f
	temp_MAX = arr_sort.last.to_f


#*********************************************************************************************
#*			       		  Normalize array values prior to calculations.				    	 *
#*********************************************************************************************
	temp_range = (temp_MAX - temp_MIN).abs
	temp_row = temp_row.map{ |x| x.valid_float? ? x.to_f : 111.111 }.dup
	temp_row.map!{ |x| x != 111.111 ? ((x - temp_MIN) / temp_range) : x}


#*********************************************************************************************
#*			       		  Set up and perform differential calculations.				    	 *
#*********************************************************************************************
	temp_row.delete_at(0)	#Delete tag name from array.
	holding_step_arr.clear
	holding_step_arr << temp_row
	holding_step_arr.flatten!
	
	holding_step_arr.delete_at(0)
	holding_step_arr << 0.0
	holding_step_arr = holding_step_arr.zip(temp_row).map{ |x, y| (y - x).abs }
	step_arr << holding_step_arr.flatten

	CSV.open(temp_file[0...-4] + " Normalized_STD.csv", 'ab') do |csv|
		csv << holding_step_arr.flatten
	end
end


#*********************************************************************************************
#*			       				Filter non-lively signals (flatlines).				    	 *
#*********************************************************************************************
step_arr.each do |temp_row|
	temp_len = temp_row.length
	temp_AVG = temp_row.dup.inject{ |x, y| y > 1 ? x : x + y } / temp_len rescue (puts "Error - Division by zero!")
	signalSTD_arr << Math.sqrt(calcVAR_Init(temp_row, temp_len, temp_AVG))
end


#*********************************************************************************************
#*			       			Calculate Variance and Standard Deviation.				    	 *
#*********************************************************************************************

association_arr = Array.new
compiled_STD = Array.new
holding_arr = Array.new
holding_arr.clear
association_arr.clear

holding_arr << ""
CSV.open(temp_file[0...-4] + " Model_Correlation.csv", 'w') do |csv|	#Append tag names as headers.
	temp_arr.each do |col_out|
		holding_arr << [col_out[0]]
	end
	csv << holding_arr.flatten
end

i = 0
j = 0
step_arr.each do |row_1|
	compiled_STD.clear
	compiled_STD << temp_arr[i][0]

	j = 0
	step_arr.each do |row_2|
		if signalSTD_arr[j] > FLATLINE_STD && signalSTD_arr[i] > FLATLINE_STD
			#temp_row = row_1.zip(row_2).map{ |x, y| x == 111.111 || y == 111.111 ? nil : (x - y).abs }.compact
			temp_row = calcSTD(row_1, row_2)
			temp_len = temp_row.length
			#temp_row = row_1.zip(row_2).reject{ |x, y| x == 111.111 || y == 111.111}.map{ |x, y| (x - y).abs }
			temp_AVG = temp_row.inject(:+) / temp_len rescue (puts "Error - Division by zero!")
			#temp_VAR = temp_row.inject(0){ |x, y| x + (y - temp_AVG)**2 } / temp_row.length
			temp_STD = Math.sqrt(calcVAR(temp_row, temp_len, temp_AVG))
		else
			temp_STD = 10
		end
		compiled_STD << temp_STD
		j += 1
	end 

	i += 1	#Increment counter prior to EOF so that printed statement is correct.

	CSV.open(temp_file[0...-4] +  " Model_Correlation.csv", 'ab') do |csv|
		csv << compiled_STD
	end
	association_arr << compiled_STD.flatten
	puts "Executed: " + i.to_s + "/" + step_arr.length.to_s
end


