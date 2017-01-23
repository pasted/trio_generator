class Variant
	attr_accessor :chrom, :pos, :id, :ref, :alt, :qual, :qual, :filter, :info, :format, :alleles
	
	def initialize(chrom, pos, id, ref, alt, qual, filter, info, format)
		self.chrom = chrom
		self.pos = pos
		self.id = id
		self.ref = ref
		self.alt = alt
		self.qual = qual
		self.filter = filter
		self.info = info
		self.format = format
		self.alleles = Hash.new
	end
	
	def variable_order						
			variable_order = [:chrom, :pos, :id, :ref, :alt, :qual, :filter, :info, :format]
			return variable_order
	end
	
	
	def alleles_to_array
		allele_array = Array.new

				self.alleles.each_pair do |this_sample_id, this_allele|
					
					allele_string = "#{this_allele.gt}:#{}"
					
					allele_hash.store("#{this_sample_id}_ad", this_allele.ad )
					allele_hash.store("#{this_sample_id}_dp", this_allele.dp )
					allele_hash.store("#{this_sample_id}_gq", this_allele.gq )
					allele_hash.store("#{this_sample_id}_gt", this_allele.gt )
					allele_hash.store("#{this_sample_id}_pl", this_allele.pl )

				end
		return allele_array
	end
		
	def print_attributes_string
			attr_string = '"'
			tmp_array = Array.new
			self.variable_order.map {|var|  tmp_array.push  "#{self.send(var)}" }
			self.alleles.each_pair do |this_key, this_allele|
				if this_allele.gt != '.'
					allele_array = Array.new
					this_allele.variable_order.map {|var| allele_array.push "#{this_allele.send(var)}" }
					allele_string = allele_array.join(":")
					tmp_array.push(allele_string)
				else
					tmp_array.push(".")
				end
			end
  		attr_string = tmp_array.join("\t")
  		return attr_string
	end
	
	def print_attributes_array
			tmp_array = Array.new
			self.variable_order.map {|var|  tmp_array.push  "#{self.send(var)}" }
			self.alleles.each do |this_allele|
				allele_array = Array.new
				this_allele.variable_order.map {|var| allele_array.push "#{self.send(var)}" }
				allele_string = allele_array.join(":")
				tmp_array.push(allele_string)
			end

  		return tmp_array
	end
		
end
