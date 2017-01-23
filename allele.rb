class Allele
	attr_accessor :ad, :dp, :gq, :gt, :pl
	#GT:GQ:DP:PL:AD
	#GT:PID:PGT:GQ:DP:PL:AD
	
	def variable_order						
			variable_order = [:gt,:gq,:dp,:pl,:ad]
			return variable_order
	end
end
