#Example workflow for generating a potential trio VCF from only the parental data
#Requires vcf-concat; vcf-sort; vcf-merge; exomiser
#Alter these to reflect the local system
java_path="java-1.8.0/java"
gatk_path="GenomeAnalysisTK-3.6.0/GenomeAnalysisTK.jar"
reference_path="resources/human_g1k_v37.fasta"
nkmi_path="resources/common_no_known_medical_impact_20160302-edited.vcf"
exac_path="resources/ExAC.r0.1.sites.vep.AF5.vcf"
exomiser_path="exomiser-cli-7.2.2.jar"
tmp_path="tmp"

#Ids used by the header line in the VCF
paternal_id="WE0001"
maternal_id="WE0002"
family_id="F0001"

${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T GenotypeGVCFs -R ${reference_path} -D /mnt/Data1/resources/dbsnp_141.b37.vcf -A FisherStrand -A VariantType -o vcfs/${paternal_id}.vcf -V gvcfs/${paternal_id}.gvcf
${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T GenotypeGVCFs -R ${reference_path} -D /mnt/Data1/resources/dbsnp_141.b37.vcf -A FisherStrand -A VariantType -o vcfs/${maternal_id}.vcf -V gvcfs/${maternal_id}.gvcf

${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T SelectVariants -R ${reference_path} -o vcfs/${paternal_id}.no-common-exac.vcf --variant vcfs/${paternal_id}.vcf --discordance ${exac_path} -U LENIENT_VCF_PROCESSING
${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T SelectVariants -R ${reference_path} -o vcfs/${maternal_id}.no-common-exac.vcf --variant vcfs/${maternal_id}.vcf --discordance ${exac_path} -U LENIENT_VCF_PROCESSING

${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T SelectVariants -R ${reference_path} -o vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf --variant vcfs/${paternal_id}.no-common-exac.vcf --discordance ${nkmi_path} -U LENIENT_VCF_PROCESSING
${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T SelectVariants -R ${reference_path} -o vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf --variant vcfs/${maternal_id}.no-common-exac.vcf --discordance ${nkmi_path} -U LENIENT_VCF_PROCESSING

cp vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf vcfs/${paternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf
cp vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf vcfs/${maternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf


##Change sample names to handle GATK SelectVariants which orders sample names by increasing number (no way to override)

sed -i "s/${paternal_id}/CHILD001/g" vcfs/${paternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf
sed -i "s/${maternal_id}/CHILD001/g" vcfs/${maternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf

sed -i "s/${maternal_id}/MATERNAL002/g" vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf
sed -i "s/${paternal_id}/PATERNAL003/g" vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf


bgzip -f vcfs/${paternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf
bgzip -f vcfs/${maternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf

tabix -f vcfs/${paternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf.gz
tabix -f vcfs/${maternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf.gz

vcf-concat vcfs/${paternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf.gz vcfs/${maternal_id}_child.no-common-exac.no-common-non-medical-impact.vcf.gz | bgzip -c > vcfs/${family_id}_potential_child.vcf.gz

vcf-sort vcfs/${family_id}_potential_child.vcf.gz | bgzip -c > vcfs/${family_id}_potential_child.sorted.vcf.gz
tabix -f vcfs/${family_id}_potential_child.sorted.vcf.gz

bgzip -f vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf
bgzip -f vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf

tabix -f vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf.gz
tabix -f vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf.gz

vcf-merge vcfs/${family_id}_potential_child.sorted.vcf.gz vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf.gz vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf.gz  > vcfs/${family_id}_potential_trio.vcf
bgzip -f vcfs/${family_id}_potential_trio.vcf
tabix -f vcfs/${family_id}_potential_trio.vcf.gz

#${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T CombineVariants -R ${reference_path} --variant vcfs/${family_id}_potential_child.sorted.vcf.gz --variant vcfs/${paternal_id}.no-common-exac.no-common-non-medical-impact.vcf.gz --variant vcfs/${maternal_id}.no-common-exac.no-common-non-medical-impact.vcf.gz -o vcfs/${family_id}_potential_trio.test.vcf
#{java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T SelectVariants -R ${reference_path} --variant vcfs/${family_id}_potential_trio.test.vcf -select '( vc.getGenotype("PATERNAL002").isHet() || vc.getGenotype("PATERNAL002").isHom() ) && ( vc.getGenotype("MATERNAL003").isHet() || vc.getGenotype("MATERNAL003").isHom() )' -o vcfs/${family_id}_trio_ready.test.vcf

#Remove de novo sites in potential proband (artefact of the vcf-merge)
${java_path} -Djava.io.tmpdir=${tmp_path} -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${gatk_path} -T SelectVariants -R ${reference_path} --variant vcfs/${family_id}_potential_trio.vcf.gz -select '( vc.getGenotype("PATERNAL003").isHet() || vc.getGenotype("PATERNAL003").isHom() ) && ( vc.getGenotype("MATERNAL002").isHet() || vc.getGenotype("MATERNAL002").isHom() )' -o vcfs/${family_id}_trio_ready.vcf
bgzip -f vcfs/${family_id}_trio_ready.vcf
tabix -f vcfs/${family_id}_trio_ready.vcf.gz

${java_path} -jar ${exomiser_path} --analysis ${family_id}.female_child.yml
