
require 'csv'
require_relative 'variant'
require_relative 'allele'

records = Array.new
variants = Array.new
vcf_record_header = ""
header = ""
#../../vcfs/F00001_potential_trio.test.vcf"
family_ids=["F00001", "F00002"]

family_ids.each do |family_id|
		File.open("../../vcfs/#{family_id}_potential_trio.test.vcf", "r") do |this_file|
			this_file.each_line do |line|
				if !line.match(/^#/)
					record = line.split(/\t/)
					this_variant = Variant.new(record[0],record[1],record[2],record[3],record[4],record[5],record[6],record[7],record[8])
					#take record[8] FORMAT
					#split by ':' into an array
					#note index of elements containing GT, GQ, DP, PL and AD
					#use this indices when assigning data from allele_array
					format_string = record[8]
					format_array = format_string.split(':')
					
					gt_index = nil
					gq_index = nil
					dp_index = nil
					pl_index = nil
					ad_index = nil
					
					format_array.each_with_index do |element, this_index|
						case element
						when "GT"
							gt_index = this_index
						when "GQ"
							gq_index = this_index
						when "DP"
							dp_index = this_index
						when "PL"
							pl_index = this_index
						when "AD"
							ad_index = this_index
						end
					end
		
					if record[9] != "."
						allele_array = record[9].split(":")
						child_allele = Allele.new
						child_allele.gt = allele_array[gt_index]
						child_allele.gq = allele_array[gq_index]
						child_allele.dp = allele_array[dp_index]
						child_allele.pl = allele_array[pl_index]
						child_allele.ad = allele_array[ad_index]
					else
						child_allele = Allele.new
						child_allele.gt = record[9]
					end
					
					if record[10] != "."
						allele_array = record[10].split(":")
						maternal_allele = Allele.new
						maternal_allele.gt = allele_array[gt_index]
						maternal_allele.gq = allele_array[gq_index]
						maternal_allele.dp = allele_array[dp_index]
						maternal_allele.pl = allele_array[pl_index]
						maternal_allele.ad = allele_array[ad_index]
					else
						maternal_allele = Allele.new
						maternal_allele.gt = record[10]
					end
					
					if record[11].strip != "."
						allele_array = record[11].split(":")
						paternal_allele = Allele.new
						paternal_allele.gt = allele_array[gt_index]
						paternal_allele.gq = allele_array[gq_index]
						paternal_allele.dp = allele_array[dp_index]
						paternal_allele.pl = allele_array[pl_index]
						paternal_allele.ad = allele_array[ad_index].strip
		
					else
						paternal_allele = Allele.new
						paternal_allele.gt = record[11].strip
					end
					records.push(record)
					this_variant.alleles["CHILD001"] = child_allele
					this_variant.alleles["MATERNAL002"] = maternal_allele
					this_variant.alleles["PATERNAL003"] = paternal_allele
					#override initial FORMAT field since only retaining 5 allelic attributes
					this_variant.format = "GT:GQ:DP:PL:AD"
					variants.push(this_variant)
				elsif line.match(/^##/)
					header << "#{line}"
				elsif line.match(/^#CHROM/)
					vcf_record_header = "#{line}"
				end
			end
					
		end
		
		edited_variants = Array.new
		
		variants.each_with_index do | this_variant, this_index|
			child_allele = this_variant.alleles["CHILD001"]
			maternal_allele = this_variant.alleles["MATERNAL002"]
			paternal_allele = this_variant.alleles["PATERNAL003"]
			
			if child_allele.gt != '1/1'
				if maternal_allele.gt == '0/1' && paternal_allele.gt == '0/1'
					maternal_allele_depths = maternal_allele.ad.split(',')
					paternal_allele_depths = paternal_allele.ad.split(',')
					hmz_child_depth = maternal_allele_depths[1].to_i + paternal_allele_depths[1].to_i
					child_allele.ad = "0,#{hmz_child_depth}"
					child_allele.dp = "#{hmz_child_depth}"
					child_allele.gq = "99"
					#hardcode the phred likelihood
					child_allele.pl = "1000,1000,0"
					child_allele.gt = "1/1"
					this_variant.alleles["CHILD001"] = child_allele
		
					variants[this_index] = this_variant
					edited_variants.push(this_variant)
				elsif maternal_allele.gt == '.' && paternal_allele.gt == '.'
					#discard variant - no calls in either mother or father
				else
					edited_variants.push(this_variant)
				end
			elsif maternal_allele.gt == '.' && paternal_allele.gt == '.'
				#discard variant - no calls in either mother or father
			end
		
			
		end
		
		
		File.open("../../vcfs/#{family_id}_potential_trio.test.edited.vcf", "w+") do |this_file|
			this_file.puts(header)
			this_file.puts(vcf_record_header)
		  edited_variants.each { |element| this_file.puts("#{element.print_attributes_string}" ) }
		end

end
