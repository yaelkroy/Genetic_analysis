#!usr/bin/perl -w

use strict;
use Scalar::Util qw(looks_like_number);
use lib './PDF-API2-2.023/lib';
#use lib './PDF-Table-0.9.9/lib';
use PDF::API2;
use PDF::Table;



main();

sub main {
   	my $fname_fluidigm = "Fluidigm_results_WomanFert_19.01.2016";
    my $patients_info_fname = "Patients_info_WomanFert_19.01.2016";
    $fname_fluidigm = "Fluidigm_results_ManFert_19.01.2016";
    $patients_info_fname = "Patients_info_ManFert_test";
    #$fname_fluidigm = "Fluidigm_results_Zhest_19.01.2016";
    #$patients_info_fname = "Patients_info_Zhest_19.01.2016";
    patients_analysis($patients_info_fname, $fname_fluidigm);
}

sub patients_analysis {
	my ($patients_info_fname, $fname_fluidigm) = @_;
	my $patients_info = {};

	get_patient_info($patients_info, $patients_info_fname);
	
	my $panels_descr = {};
	get_diseases_descr($panels_descr);
	
	
	
	while (my ($patient_id, $p_info) = each %$patients_info) {
		#next unless $patient_id eq 'F0018';
		# || $patient_id eq 'F002'|| $patient_id eq 'F003'|| $patient_id eq 'F005'|| $patient_id eq 'F008'|| $patient_id eq 'F009'|| $patient_id eq 'F0011'|| $patient_id eq 'F0013';
		while (my ($disease_code, $v) = each %{$p_info->{panels_list}}) {
			#next unless $disease_code == 1;
			my $probes_info = {};
			my $gene_disease_info = {};
			my $disease_genes = {};
			my $gene_probes = {}; 
			my $patient_fluidigm_results = {};
			my $patient_fluidigm_results_genotypes = {};
			get_panels_info( $disease_code, $gene_disease_info, $probes_info, $disease_genes, $gene_probes );
			while (my ($gene, $dis) = each %$gene_disease_info) {
				#print "$gene\t";
				while (my ($d, $v) = each %$dis) {
					#print "$d\t$v" if $d == $disease_code;
				}
				#print "\n";
			}
			my $gene_separate_page_ind = 1;
			get_genotypes_info_from_fluidigm_file_output($fname_fluidigm, $patient_id, $disease_code, $probes_info, $patient_fluidigm_results, $patient_fluidigm_results_genotypes);
			my $patient_info = {name=>$p_info->{name}, birth_date=>$p_info->{birth_date}, contract_number=>$p_info->{contract_number}, sex=>$p_info->{sex}, material=>$p_info->{material}, 
				clinic_name=>$p_info->{clinic_name}, date_obtain_material=>$p_info->{date_obtain_material}, date_result_release=>$p_info->{date_result_release}
			};
			create_pdf_on_form ($patient_fluidigm_results, $patient_fluidigm_results_genotypes, $disease_code, $patient_id, $patient_info, $panels_descr, $probes_info, $gene_disease_info, $disease_genes, $gene_probes, $gene_separate_page_ind);
		}
	}
}

sub get_patient_info {
	my ($patients_info, $patiens_fname) = @_;
	open (PI, $patiens_fname) or die "Can't open FPD $patiens_fname: $!";
	while (<PI>) {
		my $str = $_;
        $str =~ s/\n|\r|\r\n|\n\r//gi;
        my @flds = split(/\t/, $str);
        my $p_panels_list = $flds[6];
        $p_panels_list =~ s/\s+//gi;
        my @panels_list = split(/,/,$p_panels_list);
        my $patient_panels = {};
        $patient_panels->{$_}=1 for (@panels_list);
        $patients_info->{$flds[0]} = {name=>$flds[1], birth_date=>$flds[3], contract_number=>$flds[2], sex=>$flds[4], material=>$flds[5], panels_list=>$patient_panels, 
        	clinic_name=>$flds[7]?$flds[7]:"-", date_obtain_material=>$flds[8], date_result_release=>$flds[9]};
	}
	close PI;
}

sub get_diseases_descr {
	my ($panels_descr) = @_;
#	open (FPD, $fname_dis_main_descr) or die "Can't open FPD: $!";
#	while (<FPD>) {
#		my $str = $_;
#        $str =~ s/\n|\r|\r\n|\n\r//gi;
#        my @flds = split(/\t/, $str);
#        $panels_descr->{$flds[0]} = $flds[1];
#	}
#	close FPD;
	
#	while (my ($k, $v) = each %$panels_descr) {
#		print "$k\t$v\n";
#	}
	$panels_descr->{1} = "В настоящее время известно, что генетические факторы достаточно часто могут являться причиной развития репродуктивной патологии у мужчин. В ходе анализа проведено исследование микроделеций AZF-региона Y-хромосомы и количества повторов гена андрогенового рецептора (AR), ассоциированных с тяжелыми нарушениями сперматогенеза (вплоть до азооспермии). Протестированы основные мутации, обуславливающие нарушения половой дифференцировки (SRY, AMHR2). Исследовано 32 мутации и 2 полиморфных варианта в гене CFTR, связанных с обструктивными формами азооспермии. Кроме того, проанализированы частые мутации/полиморфизмы в генах TSSK2, DNAI1, KAL1, HFE, которые приводят к развитию наследственных заболеваний, одним из симптомов которые являет бесплодие.
Интерпретация результатов генетического тестирования проводится специалистом с учетом клинической картины.";
	$panels_descr->{2} = "Женское репродуктивное здоровье определяется сочетанием большого количества факторов, в том числе и генетических. Проблемы, связанные с нарушением репродуктивной функции у женщин, могут проявляться в виде бесплодия или привычного невынашивания беременности, причинами которых могут быть преждевременное истощение яичников и синдром поликистозных яичников. Все эти состояния являются многофакторными, риск их развития зависит от сочетанного воздействия различных генетических факторов и факторов внешней среды. В большинстве случаев выявленные ассоциации между наличием полиморфных вариантов и болезнью позволяют лишь говорить о риске развития патологии. Между тем, знание о своих генетических особенностях может помочь человеку выявить ключевые проблемные зоны и своевременно скорректировать образ жизни и другие экзогенные воздействия так, чтобы максимально эффективно предотвратить развитие заболевания или уменьшить степень его клинического проявления.
Выявление полиморфного варианта можно рассматривать в качестве предрасполагающего фактора к развитию патологии только в том случае, когда он обнаружен в гомозиготной форме или в сочетании с другими полиморфными вариантами.
Исследованные полиморфные варианты не являются непосредственной и обязательной причиной ассоциированного с ними заболевания, но могут обуславливать предрасположенность к его развитию. Окончательное заключение по данному анализу принимается лечащим врачом.";
	$panels_descr->{3} = "В настоящее время не вызывает сомнения факт существования генетической предрасположенности к развитию таких заболеваний как инфаркт миокарда, ишемический инсульт, ишемическая болезнь сердца, венозные тромбозы и тромбоэмболии, атеросклероз. Данное исследование позволяет определить носительство полиморфных вариантов, ассоциированных с повышенным тромбообразованием и артериальной гипертензией, которые являются основными причинами инфаркта миокарда и ишемического инсульта. Кроме того, исследуемые полиморфизмы у женщин играют важную роль в развитии таких осложнений беременности, как гестозы, фето-плацентарная недостаточность и невынашивание беременности.
Выявление полиморфного варианта можно рассматривать в качестве предрасполагающего фактора к развитию патологии только в том случае, когда он обнаружен в гомозиготной форме или в сочетании с другими полиморфными вариантами.
Исследованные полиморфные варианты не являются непосредственной и обязательной причиной ассоциированного с ними заболевания, но могут обуславливать предрасположенность к его развитию. Окончательное заключение по данному анализу принимается лечащим врачом.";
	$panels_descr->{4} = "Муковисцидоз – одно из наиболее частых наследственных заболеваний (1:10000 новорожденных). Наследуется заболевание по аутосомно-рецессивному типу и обусловлено мутациями в гене CFTR, белковый продукт которого регулирует работу хлорных и натриевых каналов в клетке. В настоящий момент описано более 2000 мутаций и 250 полиморфизмов в гене CFTR (CFTR mutation database, http://www.genet.sickkids.on.ca/cftr/), связанных с развитием данного заболевания, частоты которых широко варьируют в разных этнических группах. 
В ходе исследования протестировано 32 мутации и 2 полиморфных варианта в гене CFTR. Необходимо понимать, что в исследование включены не все, а только частые мутации в гене CFTR, ответственные за развитие 75,8% случаев заболевания. Таким образом, отсутствие мутаций по результатам анализа не может на 100% исключить наличие муковисцидоза и/или носительства других более редких мутаций в исследуемом гене. 
Интерпретация результатов генетического тестирования проводится специалистом с учетом клинической картины.";
	$panels_descr->{5} = "Риск рождения ребенка с наследственной патологией есть у всех родителей. Приблизительно половина всех случаев наследования болезней происходит, когда оба родителя не страдают наследственными заболеваниями, однако, являются носителями поврежденных генов в гетерозиготном состоянии (когда одна хромосома несет поврежденный ген, а другая – нормальный). Известно, что каждый человек является скрытым носителем в среднем 7-10 мутаций в генах, определяющих развитие наследственных заболеваний.
Данный анализ направлен на выявление гетерозиготного носительства мутаций в генах, приводящих к возникновению распространенных наследственных заболеваний. Обнаружение такого носительства позволит избежать рождения больного ребенка путем проведения дородовой (пренатальной или преимплантационной) диагностики.
В ходе исследования протестированы мутации в генах, ответственных  за возникновение 35-ти наследственных заболеваний (муковисцидоз, гепатолентикулярная дегенерация, мукополисахаридоз 1 типа, болезнь Гирке, синдром Смита-Лемли-Опица и т.д. (см. результат)).
Необходимо понимать, что протестированы не все, а только частые мутации, поэтому проведённое исследование не исключает риск носительства более редких мутаций в исследуемых генах, а также носительство мутаций в генах других заболеваний, которых к настоящему времени описано более 6000. 
При обнаружении мутации необходима консультация врача-генетика.";
	
}
sub get_panels_info {
	my ( $disease_code, $gene_disease_info, $probes_info, $disease_genes, $gene_probes ) = @_;

	my $fname_dis_main_descr = "PanelDiseases_description";
	my $fname_mutations_descr = "";
	my $fname_genes_descr = "PanelGenes_description";
	
	if ($disease_code == 1) {
		# man's fertility
		$fname_mutations_descr = "ManFert_mutations_description";
	}
	elsif ($disease_code == 2) {
		# woman's fertility
		$fname_mutations_descr = "WomanFert_mutations_description";
	}
	elsif ($disease_code == 3) {
		# thrombophilia
		$fname_mutations_descr = "Thrombophilia_mutations_description";
	}
	elsif ($disease_code == 4) {
		# cystic fbrosis
		$fname_mutations_descr = "CysticFibrosis_mutations_description";
	}
	elsif ($disease_code == 5) {
		# cystic fbrosis
		$fname_mutations_descr = "Zhest_mutations_description";
	}
	
	open (FP, $fname_mutations_descr) or die "Can't open file FP: $!";
	
	my $cnt = 0;
	while (<FP>) {
		$cnt++;
		my $str = $_;
        $str =~ s/\n|\r|\r\n|\n\r//gi;
    	my @flds = split(/\t/, $str);
    	$disease_genes->{$flds[0]}{$flds[1]} = 1;
    	$gene_probes->{$flds[1]}{$flds[4]} = 1;
    	$probes_info->{$flds[4]} = {rsid=>$flds[3], HT_name=>$flds[2], AK_name=>$flds[5], chr=>$flds[10],
    		norm_allele=>$flds[6], mut_allele=>$flds[7], norm_ac=>$flds[8], mut_ac=>$flds[9], HET=>$flds[12], MUT=>$flds[13]};
    	
	}
	close FP;
	
	open (GD, $fname_genes_descr) or die "Can't open FPD: $!";
	while (<GD>) {
		my $str = $_;
        $str =~ s/\n|\r|\r\n|\n\r//gi;
        my @flds = split(/\t/, $str);
        $gene_disease_info->{$flds[0]}{$flds[1]} = $flds[2];
	}
	close GD;
	
}
sub get_genotypes_info_from_fluidigm_file_output {
	my ($fname_fluidigm, $patient_id, $disease_code, $probes_info, $patient_fluidigm_results, $patient_fluidigm_results_genotypes) = @_;
	open (FF, $fname_fluidigm) or die "Can't open file FF: $!";
	my $cnt = 0;
	my $colnames_of_interest = {"Experiment Information_SNP Assay and Allele Names_Assay"=>"probe_id", "Experiment Information_Sample_Name"=>"patient_name", "Results_Call Information_Converted"=>"genotype",
		"User_Defined_Comments"=>"disease"
	};
	my $colnames_pos = {probe_id=>0, patient_name=>0, genotype=>0, disease=>0};
	my @colnames = ();
	while (<FF>) {
		$cnt++;
		#next if $cnt < 4;
		my $str = $_;
        $str =~ s/\n|\r|\r\n|\n\r//gi;
        my @flds = split(/\t/, $str);
		if ($cnt < 4) {
			for (my $i = 0; $i < scalar @flds; $i++) {
				$colnames[$i] = $cnt == 1?$flds[$i]:$colnames[$i]."_".$flds[$i];
			}
			if ($cnt == 3) {
				for (my $i = 0; $i < scalar @colnames; $i++) {
					$colnames_pos->{$colnames_of_interest->{$colnames[$i]}} = $i if (exists $colnames_of_interest->{$colnames[$i]});
				}
			}
			next;
		}
		my $genotype = $flds[$colnames_pos->{genotype}];
		my $probe_id = $flds[$colnames_pos->{probe_id}];
		my $patient = $flds[$colnames_pos->{patient_name}];
		my $disease = $flds[$colnames_pos->{disease}];
		
		next unless defined $patient && $patient;
		next unless $patient eq $patient_id;
		
		if (!exists $probes_info->{$probe_id}) {
			#print "Error there is no such probe ID: '".$probe_id."' in the dictionary\n";
			#print $str."\n";
			next;
		}
		print "Error in Genotype: $genotype\n\tfor probe id = $probe_id and patient = $patient\n" unless $genotype;
		next unless $genotype;
        next if $genotype eq 'NTC';
        if ($genotype eq 'No Call') {
            $patient_fluidigm_results->{$probe_id} = 'NOCALL';
            next;
        }
		my @genos = split(/:/, $genotype);
		if (scalar @genos != 2) {
			unless ($probes_info->{$probe_id}{chr} eq 'Y' && scalar @genos == 1) {
				print "Error in Genotype: $genotype\n for probe id = $probe_id and patient = $patient\n";
				next;
			}
			
		} elsif ( ($probes_info->{$probe_id}{chr} eq 'Y') && ($genos[0] ne $genos[1]) ) {
			print "Error in Genotype for Y chr SNP: $genotype\n for probe id = $probe_id and patient = $patient\n";
			next;
		}
		my $genotype_result = 'WT';
		if ($probes_info->{$probe_id}{chr} eq 'Y') {
			if ($probes_info->{$probe_id}{mut_allele} =~ m/^(\d+)\.\.\.(\d+)$/) {
				$genotype_result = 'MUT' if (int($genos[0]) >= $1 && int($genos[0]) <= $2);
			} elsif ($probes_info->{$probe_id}{mut_allele} =~ m/\//) {
				my @mut_alleles = split(/\//, $probes_info->{$probe_id}{mut_allele});
				foreach my $mut_allele (@mut_alleles) {
					if ($mut_allele eq $genos[0]) {
						$genotype_result = 'MUT';
						last;
					}
				}
			} elsif ($genos[0] eq $probes_info->{$probe_id}{mut_allele}) {
				$genotype_result = 'MUT';
				#$genotype = $genos[0];
			}
			
		}
		my $mut_cnt = 0;
		my $geno_error = 0;
		foreach my $geno (@genos) {
			if ($probes_info->{$probe_id}{mut_allele} =~ m/^(\d+)\.\.\.(\d+)$/) {
				$mut_cnt++ if (int($geno) >= $1 && int($geno) <= $2);
			} elsif ($probes_info->{$probe_id}{mut_allele} =~ m/\//) {
				my @mut_alleles = split(/\//, $probes_info->{$probe_id}{mut_allele});
				foreach my $mut_allele (@mut_alleles) {
					if ($mut_allele eq $geno) {
						$mut_cnt++;
						#$probes_info->{$probe_id}{mut_allele} = $genos[0];
						last;
					}
				}
			} elsif ($geno eq $probes_info->{$probe_id}{mut_allele}) {
				$mut_cnt++;
			} else {
				if ($probes_info->{$probe_id}{norm_allele} =~ m/^(\d+)\.\.\.(\d+)$/) {
					$geno_error = 1 unless (int($geno) >= $1 && int($geno) <= $2);
				} elsif ($probes_info->{$probe_id}{norm_allele} =~ m/\//) {
					my @norm_alleles = split(/\//, $probes_info->{$probe_id}{norm_allele});
					my $ind_ok = 0;
					foreach my $norm_allele (@norm_alleles) {
						if ($norm_allele eq $geno) {
							$ind_ok = 1;
							last;
						}
					}
					$geno_error = 1 unless ($ind_ok); 
					
				} elsif ($geno ne $probes_info->{$probe_id}{norm_allele}) {
					$geno_error = 1;
				}
				
				if ($geno_error) {
					print "Error in Genotype: $genotype\n\tfor probe id = $probe_id and patient = $patient\n";
					last;
				}
			}
		}
		if ($geno_error) {
			$patient_fluidigm_results->{$probe_id} = "NOCALL";
			next;
		}
		
		if ($mut_cnt > 0) {
			$genotype_result = $mut_cnt == 1?'HET':'MUT';
		}
		$patient_fluidigm_results->{$probe_id} = $genotype_result;
		my $patient_genotype = $genotype;
		$patient_genotype =~ s/:/\//;
		$patient_genotype = $genos[0] if ($probes_info->{$probe_id}{chr} eq 'Y');
		$patient_fluidigm_results_genotypes->{$probe_id} = $patient_genotype;
	}
	close FF;
	
}


sub create_header {
	my ($pdf, $page, $p_info, $text_params) = @_;
	
    my $font = $text_params->{font};
    my $fontbd = $text_params->{fontbd};
    my $fontbi = $text_params->{fontbi};
    my $fonti = $text_params->{fonti};

	my $font_size =  $text_params->{font_size};
    my $y0 = $text_params->{colontitul_begins_y0};
    my $x0 = $text_params->{colontitul_begins_x0};;
    my $d = $text_params->{d};;
	

    my $patient_str = "Фамилия, имя, отчество обследуемого: ";
    my $disease_str = "Панель: ";
    my $contract_str = "Идентификатор/№ договора: ";
    my $birthdate_str = "Дата рождения обследуемого (ДД.ММ.ГГГГ): ";
    my $sex_str = "Пол обследуемого (М/Ж): ";
    my $material_str = "Материал для анализа: ";

   

    my $text = $page->text();
	$text->fillcolor('#4C5864');

	$text->font($font, $font_size);
    $text->translate($x0, $y0);
    $text->text($contract_str);
    $text->font($fontbd, $font_size);
    $text->text($p_info->{contract_number});
    $y0 -= $d;
    $text->translate($x0, $y0);
    $text->font($font, $font_size);
    $text->text($patient_str);
    $text->font($fontbd, $font_size);
    $text->text($p_info->{name});

	$y0 -= $d;
	$text->translate($x0, $y0);
	$text->font($font, $font_size);
    $text->text($birthdate_str);
    $text->font($fontbd, $font_size);
    $text->text($p_info->{birth_date});
    
    $y0 -= $d;
	$text->translate($x0, $y0);
	$text->font($font, $font_size);
    $text->text($sex_str);
    $text->font($fontbd, $font_size);
    $text->text($p_info->{sex});
    
	
	$y0 -= $d;
	$text->translate($x0, $y0);
	$text->font($font, $font_size);
    $text->text($material_str);
    $text->font($fontbd, $font_size);
    $text->text($p_info->{material});
#############
	$y0 -= $d;
	$text->translate($x0, $y0);
	$text->font($font, $font_size);
    $text->text("Клиника: ");
    $text->font($fontbd, $font_size);
    $text->text($p_info->{clinic_name});

	$y0 -= $d;
	$text->translate($x0, $y0);
	$text->font($font, $font_size);
    $text->text("Дата получения материала: ");
    $text->font($fontbd, $font_size);
    $text->text($p_info->{date_obtain_material});

	$y0 -= $d;
	$text->translate($x0, $y0);
	$text->font($font, $font_size);
    $text->text("Дата выдачи: ");
    $text->font($fontbd, $font_size);
    $text->text($p_info->{date_result_release});
	
}


sub create_pdf_on_form {
	my ($patient_fluidigm_results, $patient_fluidigm_results_genotypes, $disease_code, $patient_id, $patient_info, $panels_descr, $probes_info, $gene_disease_info, $disease_genes, $gene_probes, $gene_separate_page_ind) = @_;
	
	my $disease_names = {1=>'МУЖСКАЯ ФЕРТИЛЬНОСТЬ', 2=> 'ЖЕНСКАЯ ФЕРТИЛЬНОСТЬ', 3=>'ТРОМБОФИЛИЯ', 4=>'МУКОВИСЦИДОЗ', 5=>'ПОДГОТОВКА К БЕРЕМЕННОСТИ'};
	
	$gene_separate_page_ind = 1 unless defined $gene_separate_page_ind;
	
	#####################################
	# About PDF part
	#####################################
    my $pdf = PDF::API2->new();
    my $page = $pdf->page();
    my $page_number;
    $page = $pdf->openpage($page_number);

    $page->mediabox('A4');
    my $font =$pdf->ttfont('Arial.ttf',-encode=>'utf8');
    my $fontbd =$pdf->ttfont('Timesbd.ttf',-encode=>'utf8');
    my $fontbi =$pdf->ttfont('Timesbi.ttf',-encode=>'utf8');
    my $fonti =$pdf->ttfont('Timesi.ttf',-encode=>'utf8');
	
	my $colontitul_params_text_params = {font=>$font, fontbd=>$fontbd, fontbi=>$fontbi, fonti=>$fonti, font_size=>9, colontitul_begins_y0=>825, colontitul_begins_x0=>20, d=>12};
	 
    
    
    #create_header($pdf, $page, $patient_name, $patient_birth, $patient_contract_number, $patient_sex, $patient_material);
    my $text = $page->text();
	my $font_size =  10;
    my $y0 = 385;
    my $x0 = 20;
    my $d = 17;
	my $print_width = 555;
	
	
	my $detected_genes = {};
	my $analyzed_genes_muts = "";
	my @sorted_genes = sort { $a cmp $b } keys %{$disease_genes->{$disease_code}};
	
	foreach my $gene (@sorted_genes) {
		foreach my $probe (keys %{$gene_probes->{$gene}}) {
			if (exists $patient_fluidigm_results->{$probe}) {
				if ($patient_fluidigm_results->{$probe} ne 'NOCALL') {
					if ($patient_fluidigm_results->{$probe} ne 'WT') {
						my $descr = $patient_fluidigm_results->{$probe} eq 'HET'?$probes_info->{$probe}{HET}:$probes_info->{$probe}{MUT};
						if ($gene eq 'AR' && $disease_code == 2 &&  $patient_fluidigm_results->{$probe} eq 'MUT') {
							my @gs = split(/\//, $patient_fluidigm_results_genotypes->{$probe});
							if (scalar (@gs) == 2) {
								if ( ($gs[0] >= 10 && $gs[0] <= 17 && $gs[1] >= 27 && $gs[1] <= 50) || ($gs[1] >= 10 && $gs[1] <= 17 && $gs[0] >= 27 && $gs[0] <= 50) ) {
									$descr = "Обнаружена комбинация короткого и длинного аллелей в гене AR (длина нормального аллеля 18-26 CAG повторов). Необходима консультация врача-генетика.";
								}
							}
						}
						my $mut_name = $probes_info->{$probe}{HT_name};
						$mut_name .= " (".$probes_info->{$probe}{AK_name}.")" if $probes_info->{$probe}{AK_name};
						$detected_genes->{$gene}{$probe} = {NAME=>$mut_name, STATUS=>$patient_fluidigm_results->{$probe}, DESCR=>$descr};
					}
				}
			}
		}
	}
	my $x0_d = 8.85;
	my $main_page_text_params = {font=>$font, fontbd=>$fontbd, fontbi=>$fontbi, fonti=>$fonti, font_size=>9, header_y0=>700, x0=>$x0+$x0_d, d=>17, print_width=>555-$x0_d};
	
    my $table_result_y0 = print_main_page($pdf, $page, $disease_code, $panels_descr, $disease_names, \@sorted_genes, $gene_probes, $probes_info, $patient_info, $colontitul_params_text_params, $main_page_text_params);
	
 	if (scalar (keys %$detected_genes) > 0) {
		my $pdf_table_data = [["Ген","Мутация", "Комментарий"]];
		foreach my $gene (sort { $a cmp $b } keys %$detected_genes) {
			my $probes_val = $detected_genes->{$gene};
		#while (my ($gene, $probes_val) = each %$detected_genes) {
			my $ind_no_hline = scalar(keys %$probes_val) > 1?1:0;
			my $inner_row = 0;
			foreach my $probe (sort { $a cmp $b } keys %$probes_val) {
				my $probe_val = $probes_val->{$probe};
			#while (my ($probe, $probe_val) = each %$probes_val) {
				if ($inner_row == 0) {
					push @$pdf_table_data, [$gene, $probe_val->{NAME}, $probe_val->{DESCR}];
				} else {
					if ($ind_no_hline) {
						push @$pdf_table_data, ["", $probe_val->{NAME}, $probe_val->{DESCR}];
					} else {
						push @$pdf_table_data, [$gene, $probe_val->{NAME}, $probe_val->{DESCR}];
					}
				}
				$inner_row++;
			}			
		}
		my $table_font_size = 7;
		#$table_params = {x0=>$x0, y0=>$y0, width=>$print_width, font_size=>$table_font_size, y0_new_page=> 670, col1_w=>50, col2_w=>70, col3_w=>435};
		my $table_params = {font=>$font, fontbd=>$fontbd, fontbi=>$fontbi, fonti=>$fonti, x0=>$x0, y0=>$table_result_y0, width=>$print_width, 
			font_size=>$table_font_size, header_x0=> $x0+$x0_d, y1=>40, header_y0=>700, header_font_size=>13, y0_new_page=> 670, col1_w=>50, col2_w=>70, col3_w=>435, d=>9};
		$table_result_y0 = draw_table($pdf, $page, $table_params, $patient_info, $colontitul_params_text_params, $pdf_table_data);
		
	} else {
		$text->font($font, $font_size);
		$text->translate($x0+4, $table_result_y0-10);
		$text->fillcolor('black');
		if ($disease_code == 4) {
			$text->text("Мутаций среди исследуемых в гене ");
			$text->font($fonti, $font_size);
			$text->text("CFTR ");
		} else {
			$text->text("Мутаций среди исследуемых в указанных генах ");
		}
		
		$text->font($fontbd, $font_size);
		$text->fillcolor('#4C5864');
		$text->text("НЕ ОБНАРУЖЕНО");
	}
 	my $tech_font_size = 7;
    my $tech_y0 = 670;
    my $tech_x0 = 20;
    my $tech_header_y0 = 700;
    my $tech_header_x0 = $x0 + $x0_d;
    my $tech_header_font_size = 11;
	
	my $azf_cnt = 0;
	my $tech_report_results = [];
	push @$tech_report_results, ["Ген", "RSID", "Мутация(НТ)", "Мутация(АК)", "Генотип(НТ)", "Генотип(АК)", "Комментарий"];
	my $genes_descrs = [];
	
	
	foreach my $gene (@sorted_genes) {
		my $gene_name = $gene;
		$gene_name = 'AZF' if $gene eq 'AZFa' || $gene eq 'AZFb' || $gene eq 'AZFc';
		next unless exists $gene_disease_info->{$gene_name}{$disease_code};
		if ($gene_name eq 'AZF') {
			$azf_cnt++;
		}
		#################################### 
		next if ($gene_name eq "AZF" && $azf_cnt > 1);
		
		my $gene_name_text = $gene_name.":";
		if ($gene_name eq "AZF") {
			$gene_name_text = "AZFa, AZFb и AZFc:";
		}
		
		if ($disease_code != 4) {
			push @$genes_descrs, [$gene_name_text, $gene_disease_info->{$gene_name}{$disease_code}];
		}
	}
	
	if ($disease_code != 4) {
		my $genes_descr_params = {font=>$font, fontbd=>$fontbd, fontbi=>$fontbi, fonti=>$fonti, font_size=>10, 
			print_width=>$print_width-$x0_d, y0=>670, header_y0=>700,y1=>25, x0=>$x0+$x0_d, d=>17};
		
		print_genes_description_new_page($pdf, $patient_info, $colontitul_params_text_params, $genes_descr_params, $genes_descrs);
	}
	#######################################################
	foreach my $gene (@sorted_genes) {
		my $gene_name = $gene;
		$gene_name = 'AZF' if $gene eq 'AZFa' || $gene eq 'AZFb' || $gene eq 'AZFc';
		next unless exists $gene_disease_info->{$gene_name}{$disease_code};
		
		my $cnt_genes_for_tech_report = 0;
		#next unless $cnt_called_probes_for_gene;
		foreach my $pat_probe (sort { $a cmp $b } keys %$patient_fluidigm_results) {
			my $pat_genotype = $patient_fluidigm_results->{$pat_probe};
		#while (my ($pat_probe, $pat_genotype) = each %$patient_fluidigm_results) {
			next if $pat_genotype eq 'NOCALL';
			next unless exists $gene_probes->{$gene}{$pat_probe};
			$cnt_genes_for_tech_report++;
			my $descr = "НЕ ОБНАРУЖЕНО";
			my ($genotype_HT, $genotype_AK);
			my $genotype_HT_new = $patient_fluidigm_results_genotypes->{$pat_probe};
			if ($pat_genotype eq 'WT') {
				$genotype_HT = $probes_info->{$pat_probe}{norm_allele};
				$genotype_AK = $probes_info->{$pat_probe}{norm_ac};
			} else {
				$descr = "ОБНАРУЖЕНА МУТАЦИЯ";
				$genotype_HT = $probes_info->{$pat_probe}{mut_allele};
				$genotype_AK = $probes_info->{$pat_probe}{mut_ac};
			}
			
			if ($probes_info->{$pat_probe}{chr} ne 'Y') {
				if ($pat_genotype eq 'WT') {
					$genotype_HT .= '/'.$probes_info->{$pat_probe}{norm_allele};
					$genotype_AK .= '/'.$probes_info->{$pat_probe}{norm_ac} if ($genotype_AK && $probes_info->{$pat_probe}{norm_ac});
				} elsif ($pat_genotype eq 'HET') {
					$descr .= " В ГЕТЕРОЗИГОТНОЙ ФОРМЕ";
					$genotype_HT = $probes_info->{$pat_probe}{norm_allele}."/".$genotype_HT;
					if ($genotype_AK && $probes_info->{$pat_probe}{norm_ac}) {
						$genotype_AK = $probes_info->{$pat_probe}{norm_ac}."/".$genotype_AK;
					} 
				
				} else {
					$descr .= " В ГОМОЗИГОТНОЙ ФОРМЕ";
					$genotype_HT .= "/".$probes_info->{$pat_probe}{mut_allele} if $probes_info->{$pat_probe}{mut_allele};
					$genotype_AK .= "/".$probes_info->{$pat_probe}{mut_ac} if $probes_info->{$pat_probe}{mut_ac};
				}
			}
			if ($cnt_genes_for_tech_report == 1) {
				push @$tech_report_results, [$gene, $probes_info->{$pat_probe}{rsid}, $probes_info->{$pat_probe}{HT_name}, $probes_info->{$pat_probe}{AK_name}, $genotype_HT_new, $genotype_AK, $descr];

			} else {
				push @$tech_report_results, ["", $probes_info->{$pat_probe}{rsid}, $probes_info->{$pat_probe}{HT_name}, $probes_info->{$pat_probe}{AK_name}, $genotype_HT_new, $genotype_AK, $descr];
			}
		}
	}
	my $tech_table_params = {font=>$font, fontbd=>$fontbd, fontbi=>$fontbi, fonti=>$fonti, font_size=>10,
		x0=>$tech_x0, y0=>$tech_y0, width=>$print_width, font_size=>$tech_font_size, col1_w=>50, col2_w=>80, col3_w=>80, col4_w=>95, col5_w=>65, col6_w=>55, col7_w=>130,
		header_y0=>$tech_header_y0, header_x0=>$tech_header_x0, header_font_size=>$tech_header_font_size, y1=>90, d=>$tech_font_size+2};
	print_technical_report($pdf, $tech_table_params, $patient_info, $colontitul_params_text_params, $tech_report_results);
	
	$page = $pdf->openpage(-1);
	$text = $page->text();
	$text->fillcolor('black');
	$text->font($font, 9);
	
	my $t1 = "Врач-генетик ______________________________________________";
	my $t2 = "Зав. лабораторией ДНК-диагностики _______________________________ Е.А. Померанцева";
    my $tw1 = $text->advancewidth( $t1 );
	my $tw2 = $text->advancewidth( $t2 );

	$text->translate(575-$tw1, 80);
    $text->text($t1);
	$text->translate(575-$tw2, 40);
    $text->text($t2);
	print ($tw1."\n");
	print($tw2."\n");
	
	my $pagenumber = $pdf->pages;
	
	for (my $page_i= 1; $page_i <= $pagenumber; $page_i++) {
		$page = $pdf->openpage($page_i);
		$text = $page->text();
		$text->fillcolor('black');
		$text->font($font, 7);
	
		my $t = 'стр. '.$page_i." из ".$pagenumber;
	    my $tw = $text->advancewidth( $t );

		$text->translate( (575-$tw)/2.0, 10 );
    	$text->text($t);
	}
	
	my $pdf_result_name = 'Fluidigm_results_PanelID_'.$disease_code.'_Patient_'.$patient_id.'_19.01.2016.pdf';
	$pdf->saveas($pdf_result_name);
	print "Result PDF file is printed\n";
	########################
}
sub print_main_page {
	my ($pdf, $page, $disease_code, $panels_descr, $disease_names, $sorted_genes, $gene_probes, $probes_info, $patient_info, $colontitul_params_text_params, $main_page_text_params) = @_;
	
	my $text = $page->text();
	my $font = $main_page_text_params->{font};
    my $fontbd =$main_page_text_params->{fontbd};
    my $fontbi =$main_page_text_params->{fontbi};
    my $fonti =$main_page_text_params->{fonti};
 
    
    
    create_header($pdf, $page, $patient_info, $colontitul_params_text_params);
   
	
	my $d = $main_page_text_params->{d};
	my $font_size =   $main_page_text_params->{font_size};
	my $header_y0 =  $main_page_text_params->{header_y0};
    my $x0 =  $main_page_text_params->{x0};
	my $print_width =  $main_page_text_params->{print_width};
	
	my $gfx_bg = $page->gfx;
	$gfx_bg->rect( 10, $header_y0,  13, 11);
    $gfx_bg->fillcolor('#0B4E91');
    $gfx_bg->fill();
    $gfx_bg->fillcolor('black');
	
	$text->fillcolor('#0B4E91');
	$text->translate($x0, $header_y0);
	$text->font($font, 15);
    $text->text("ПАНЕЛЬ: ");
    $text->text($disease_names->{$disease_code});
	$text->fillcolor('black');
	
	my $y0 = $header_y0 - 37;
	$text->translate($x0, $y0);
	$text->font($fontbd, 13);
    $text->text("Описание панели ");
    
	$y0 -= 23;
	$y0 = text_pdf_output($pdf, $page, $text, $panels_descr->{$disease_code}, $print_width, $x0, $y0, $d, $font, $font_size);
    
    $y0 -= 30;
	$text->translate($x0, $y0);
	$text->font($fontbd, 13);
	$text->text("Анализируемые гены и мутации");
	$y0 -= 23;		

	my $analyzed_genes_muts = "";
	my @analyzed_genes_mut = ();
	
	
	foreach my $gene (@$sorted_genes) {
		my $probe_names_called = "";
		foreach my $probe (sort { $a cmp $b } keys %{$gene_probes->{$gene}}) {
			$probe_names_called .= $probe_names_called?", ".$probes_info->{$probe}{HT_name}:$probes_info->{$probe}{HT_name};
		}
		if ($probe_names_called) {
			$analyzed_genes_muts .= $analyzed_genes_muts?", ".$gene."(".$probe_names_called.")":$gene."(".$probe_names_called.")";
		}
	}

	$y0 = text_pdf_output($pdf, $page, $text, $analyzed_genes_muts, $print_width, $x0, $y0, $d, $font, $font_size);
	$y0 -= 1.5*$d;
	$text->font($fontbd, 13);
	$text->translate($x0, $y0);
	$text->text("Ваш результат:");
	$y0 -= 23;
	return($y0);
}
sub print_genes_description_new_page {
	my ($pdf, $patient_info, $colontitul_params_text_params, $genes_descr_params, $genes_sorted, $iter) = @_;
	
	$iter = 0 unless defined $iter;
	my $page = $pdf->page();

    # Retrieve an existing page
    my $page_number;
    $page = $pdf->openpage($page_number);

    # Set the page size
    $page->mediabox('A4');

    my $font = $genes_descr_params->{font};
    my $fontbd = $genes_descr_params->{fontbd};
    my $fontbi = $genes_descr_params->{fontbi};
    my $fonti = $genes_descr_params->{fonti};

	create_header($pdf, $page, $patient_info, $colontitul_params_text_params);


    my $text = $page->text();
	
	
	#my $font_size = 10;
    #my $print_width = 555 - 8.85;
    #my $y0 = 690;
    #my $header_y0 = 720;
    #my $y1 = 10;
    #my $x0 = 20 + 8.85;
    #my $d = 17;
	
	my $font_size = $genes_descr_params->{font_size};
    my $print_width = $genes_descr_params->{print_width};
    my $y0 = $genes_descr_params->{y0};
    my $header_y0 = $genes_descr_params->{header_y0};
    my $y1 = $genes_descr_params->{y1};
    my $x0 = $genes_descr_params->{x0};
    my $d = $genes_descr_params->{d};


    
	$text->font($fontbd, 11);
	$text->translate($x0, $header_y0);
	$text->fillcolor('#0B4E91');
	$text->text("ОПИСАНИЕ АНАЛИЗИРУЕМЫХ ГЕНОВ/ЛОКУСОВ ДЛЯ ДАННОЙ ПАНЕЛИ");
	$text->fillcolor('black');

	my $i = $iter;
	my $y_next_eight = $y0;
	if ($i < scalar(@$genes_sorted)) {
		$y_next_eight = $font_size + $d/4;
		$y_next_eight += analyze_text_height($text, $genes_sorted->[$i][1], $print_width, $font,  $font_size-1);
	}
	
	while ($i < scalar(@$genes_sorted) && $y_next_eight < $y0 - $y1) {
		my $gene_item = $genes_sorted->[$i];
		$text->translate($x0, $y0);
		$text->font($fontbi, $font_size);
		$text->text($gene_item->[0]);	
		$y0 -= $d/4;
		$y0 = text_pdf_output($pdf, $page, $text, $gene_item->[1], $print_width, $x0, $y0, $d, $font, $font_size-1);
		$y0 -= $d/2;
		$i++;
		if ($i < scalar(@$genes_sorted)) {
			$y_next_eight = $font_size + $d/4;
			$y_next_eight += analyze_text_height($text, $genes_sorted->[$i][1], $print_width, $font,  $font_size-1);
		}
	}
	print_genes_description_new_page($pdf, $patient_info, $colontitul_params_text_params, $genes_descr_params, $genes_sorted, $i) if $i < scalar(@$genes_sorted);
}

sub analyze_text_height {
	my ($text, $text_str, $print_width, $font, $font_size) = @_;
	$text_str = "" unless defined $text_str;
	$text->font($font, $font_size);
	my @words = split(/\s/, $text_str);
	my $x_temp = 0;
	my $y_temp = 842;
	my $space_w = $text->advancewidth( "\x20" );
	my $print_end = $print_width;
	my $word_widths = {};

	 for (my $i = 0; $i < scalar(@words); $i++) {
	 	my $word_width = $text->advancewidth( $words[$i] );
	 	$word_width += $space_w unless $i == scalar(@words) - 1;
    	if ($i == 0 || $print_end - $x_temp < $word_width) {
    		$y_temp -= $font_size + 2;
    		$x_temp = 0;
    	}
		$x_temp += $word_width;
	 }
	 $y_temp -= $font_size;
	 return 842 - $y_temp;
}

sub text_pdf_output {
	my ($pdf, $page, $text, $text_str, $print_width, $x0, $y0, $d, $font, $font_size) = @_;
	$text_str = "" unless defined $text_str;
	my @words = split(/\s/, $text_str);
	 my $x_temp = $x0;
	 my $y_temp = $y0;
	 my $space_w = $text->advancewidth( "\x20" );
	 $text->font($font, $font_size);
	 my $print_end = $print_width + $x0;
	 for (my $i = 0; $i < scalar(@words); $i++) {
	 	$words[$i] .= " " unless $i == scalar(@words) - 1;
	 	my $word_width = $text->advancewidth( $words[$i] );
	 	$word_width += $space_w unless $i == scalar(@words) - 1;
    	if ($i == 0 || $print_end - $x_temp < $word_width) {
    		$y_temp -= $font_size + 2;
    		$x_temp = $x0;
    	}
    	$text->translate($x_temp, $y_temp);
		$text->text($words[$i]);  
		$x_temp += $word_width;
	 }
	 $y_temp -= $font_size;
	 return $y_temp;
}

sub print_technical_report {
	my ($pdf, $table_params, $patient_info, $colontitul_params_text_params, $res, $res_cnter, $last_gene_name) = @_;
	############
   # Add a blank page
    my $page = $pdf->page();
    $res_cnter = 0 unless defined $res_cnter && $res_cnter;
    $last_gene_name = "" unless defined $last_gene_name;

    # Retrieve an existing page
    my $page_number;
    $page = $pdf->openpage($page_number);

    # Set the page size
    $page->mediabox('A4');

    my $font = $table_params->{font};
    my $fontbd = $table_params->{fontbd};
    my $fontbi = $table_params->{fontbi};
    my $fonti = $table_params->{fonti};

	create_header($pdf, $page, $patient_info, $colontitul_params_text_params);


    my $text = $page->text();
	
	
	##############
 	
 	my $font_size = $table_params->{font_size};
    my $print_width = $table_params->{width};
    my $y0 =  $table_params->{y0};
    my $x0 =  $table_params->{x0};
    my $header_y0 = $table_params->{header_y0};
    my $header_x0 = $table_params->{header_x0};
    my $header_font_size = $table_params->{header_font_size};
	
	$text->translate($header_x0, $header_y0);
	$text->font($fontbd, $header_font_size);
	$text->fillcolor('#0B4E91');
	$text->text("ТЕХНИЧЕСКИЙ ОТЧЕТ");
	$text->fillcolor('black');
	my $y1 = $table_params->{y1};
	my $gfx = $page->gfx;
	my $border_color ='black';
	my $line_w        = 1;
    $gfx->strokecolor($border_color);
    $gfx->linewidth($line_w);

    
    my $d = $table_params->{d};
    my $padding_col = 5;
    my $y_text = $y0 - $d;
    my $x_text = $x0 + $d;
    $text->font($font, $font_size);
    
    my $col1_x0 = $x0;
    my $col2_x0 = $x0 + $table_params->{col1_w};
    my $col3_x0 = $col2_x0 + $table_params->{col2_w};
    my $col4_x0 = $col3_x0 + $table_params->{col3_w};
    my $col5_x0 = $col4_x0 + $table_params->{col4_w};
    my $col6_x0 = $col5_x0 + $table_params->{col5_w};
    my $col7_x0 = $col6_x0 + $table_params->{col6_w};
    my $end_vline = $col7_x0 + $table_params->{col7_w};
    my ($y_bottom, $y_temp);
    $y_bottom = $y0;
    
    if (scalar (@$res) - $res_cnter > 0 && scalar (@$res) > 1) {
    	####
    	$gfx->move( $x0, $y_bottom );
		$gfx->hline($x0 + $table_params->{width} );
    	$y_text = $y_bottom - $d/2;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][0], $table_params->{col1_w} - 2*$d, $col1_x0 + $d, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][1], $table_params->{col2_w} - 2*$padding_col, $col2_x0 + $padding_col, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][2], $table_params->{col3_w} - 2*$padding_col, $col3_x0 + $padding_col, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][3], $table_params->{col4_w} - 2*$padding_col, $col4_x0 + $padding_col, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][4], $table_params->{col5_w} - 2*$padding_col, $col5_x0 + $padding_col, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][5], $table_params->{col6_w} - 2*$padding_col, $col6_x0 + $padding_col, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][6], $table_params->{col7_w} - 2*$padding_col, $col7_x0 + $padding_col, $y_text, $d, $fontbd, $font_size);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
    	$gfx->move( $x0, $y_bottom );
    	$gfx->hline($x0 + $table_params->{width} );
    	
    	$res_cnter = 1 if ($res_cnter == 0);
    	my $i = $res_cnter;
    	my $y_next_eight = $y_bottom;
		if ($i < scalar(@$res)) {
			$y_next_eight = analyze_text_height($text, $res->[$i][6], $table_params->{col7_w} - 2*$padding_col, $font, $font_size);
			#print ($y_bottom."\t".$y_next_eight."\n");
		}
    	while ($y_next_eight < $y_bottom - $y1 && $i < scalar(@$res)) {
    	
    	#for (my $i = $res_cnter; $i < scalar(@$res); $i++) {
    	#my $last_gene_name = "";
    	#while ($y_bottom > $y1 && $i < scalar(@$res)) {
    		my $res_it = $res->[$i];
    		
    		if ($res_it->[0]) {
			    $gfx->move( $x0, $y_bottom );
			    $gfx->hline($x0 + $table_params->{width} );
    		}
    		else {
    			$gfx->move(  $col2_x0, $y_bottom );
		    	$gfx->hline( $col2_x0 + $table_params->{width} - $table_params->{col1_w} );
    		}
    		$y_text = $y_bottom - $d/2;
    		my $gene_name = $res_it->[0];
    		if ($i == $res_cnter && !$res_it->[0]) {
    			$gene_name = $last_gene_name
    		}
    		if ($res_it->[0]) {
    			$last_gene_name = $gene_name;
    		}
		    $y_temp = text_pdf_output($pdf, $page, $text, $gene_name, $table_params->{col1_w} - 2*$d, $col1_x0 + $d, $y_text, $d, $fonti, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[1], $table_params->{col2_w} - 2*$padding_col, $col2_x0 + $padding_col, $y_text, $d, $font, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[2], $table_params->{col3_w} - 2*$padding_col, $col3_x0 + $padding_col, $y_text, $d, $font, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[3], $table_params->{col4_w} - 2*$padding_col, $col4_x0 + $padding_col, $y_text, $d, $font, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[4], $table_params->{col5_w} - 2*$padding_col, $col5_x0 + $padding_col, $y_text, $d, $font, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[5], $table_params->{col6_w} - 2*$padding_col, $col6_x0 + $padding_col, $y_text, $d, $font, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[6], $table_params->{col7_w} - 2*$padding_col, $col7_x0 + $padding_col, $y_text, $d, $font, $font_size);
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $i++;
		    if ($i < scalar(@$res)) {
				$y_next_eight = analyze_text_height($text, $res->[$i][6], $table_params->{col7_w} - 2*$padding_col, $font, $font_size);
				#print ("Inner: ".$y_bottom."\t".$y_next_eight."\n");
			}
    	}
	    $gfx->move( $x0, $y_bottom );
	    $gfx->hline($x0 + $table_params->{width} );
    	
    	$gfx->move(  $col1_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col2_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col3_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col4_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col5_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col6_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col7_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $end_vline, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->stroke;
	    
	    print_technical_report($pdf, $table_params, $patient_info, $colontitul_params_text_params, $res, $i, $last_gene_name) if $i < scalar(@$res);
	    $y_bottom -= $d;
    	
    }
    
    
    return $y_bottom;
}

sub draw_table {
	my ($pdf, $page, $table_params, $patient_info, $colontitul_params_text_params, $res, $res_cnter, $last_gene_name) = @_;
	
	my $new_page_ind = 0;
	$new_page_ind = 1 if defined $res_cnter;
	$res_cnter = 0 unless defined $res_cnter;
	$last_gene_name = "" unless defined $last_gene_name;
	
	#my $table_params = {x0=>$x0, y0=>$y0, width=>$print_width, font_size=>$table_font_size, y0_new_page=> 670, col1_w=>50, col2_w=>70, col3_w=>435};
	
	my $gfx = $page->gfx;
	my $border_color = 'black';
	my $line_w        = 1;
    $gfx->strokecolor($border_color);
    $gfx->linewidth($line_w);

    my $fontbd =$table_params->{fontbd};
    my $fontbi =$table_params->{fontbi};
    my $fonti = $table_params->{fonti};
   	my $font = $table_params->{font};
   
    my $gfx_bg = $page->gfx;

    my $d = $table_params->{d};
    my $padding_col2 = 5;
    my $padding_col3 = 5;
    my $y0 = $new_page_ind?$table_params->{y0_new_page}:$table_params->{y0};
    my $y_text = $y0 - $d;
    my $x0 = $table_params->{x0};

    my $text = $page->text();
    $text->font($font, $table_params->{font_size});
    my $col1_x0 = $x0;
    my $col2_x0 = $x0 + $table_params->{col1_w};
    my $col3_x0 = $col2_x0 + $table_params->{col2_w};
    my $end_vline = $col3_x0 + $table_params->{col3_w};
    my ($y_bottom, $y_temp);
    $y_bottom = $y0;
    my $y1 = $table_params->{y1};
    my $header_y0 = $table_params->{header_y0};
    my $header_x0 = $table_params->{header_x0};
    my $header_font_size = $table_params->{header_font_size};
    ###################
    if (scalar (@$res) - $res_cnter > 0 && scalar (@$res) > 1) {
    	####
    	my $y_header = $y_bottom;
    	$gfx->move( $x0, $y_bottom );
		$gfx->hline($x0 + $table_params->{width} );
    	$y_text = $y_bottom - $d/2;
    	$text->fillcolor('white');
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][0], $table_params->{col1_w} - 2*$d, $col1_x0 + $d, $y_text, $d, $fontbd, $table_params->{font_size}+2);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][1], $table_params->{col2_w} - 2*$padding_col2, $col2_x0 + $padding_col2, $y_text, $d, $fontbd, $table_params->{font_size}+2);
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		$y_temp = text_pdf_output($pdf, $page, $text, $res->[0][2], $table_params->{col3_w} - 2*$padding_col3, $col3_x0 + $padding_col3, $y_text, $d, $fontbd, $table_params->{font_size}+2);
		$text->fillcolor('black');
		$y_bottom = $y_temp if $y_temp < $y_bottom;
		my $y1_header = $y_bottom;
		$gfx_bg->rect( $x0, $y1_header,  $table_params->{width}, $y_header - $y1_header);
        $gfx_bg->fillcolor('#0B4E91');
        $gfx_bg->fill();
        $gfx_bg->fillcolor('black');
    	$gfx->move( $x0, $y_bottom );
    	$gfx->hline($x0 + $table_params->{width} );
    	$res_cnter = 1 if ($res_cnter == 0);
    	my $i = $res_cnter;
    	my $y_next_eight = $y_bottom;
		if ($i < scalar(@$res)) {
			$y_next_eight = analyze_text_height($text, $res->[$i][2], $table_params->{col3_w} - 2*$padding_col3, $font, $table_params->{font_size});
			#print ($y_bottom."\t".$y_next_eight."\n");
		}
    	while ($y_next_eight < $y_bottom - $y1 && $i < scalar(@$res)) {
    		my $res_it = $res->[$i];

    		if ($res_it->[0]) {
			    $gfx->move( $x0, $y_bottom );
			    $gfx->hline($x0 + $table_params->{width} );
    		}
    		else {
    			$gfx->move(  $col2_x0, $y_bottom );
		    	$gfx->hline( $col2_x0 + $table_params->{width} - $table_params->{col1_w} );
    		}
    		my $gene_name = $res_it->[0];
    		if ($i == $res_cnter && !$res_it->[0]) {
    			$gene_name = $last_gene_name
    		}
    		if ($res_it->[0]) {
    			$last_gene_name = $gene_name;
    		}
    		$y_text = $y_bottom - $d/2;
		    $y_temp = text_pdf_output($pdf, $page, $text, $gene_name, $table_params->{col1_w} - 2*$d, $col1_x0 + $d, $y_text, $d, $fonti, $table_params->{font_size});
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[1], $table_params->{col2_w} - 2*$padding_col2, $col2_x0 + $padding_col2, $y_text, $d, $font, $table_params->{font_size});
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $y_temp = text_pdf_output($pdf, $page, $text, $res_it->[2], $table_params->{col3_w} - 2*$padding_col3, $col3_x0 + $padding_col3, $y_text, $d, $font, $table_params->{font_size});
		    $y_bottom = $y_temp if $y_temp < $y_bottom;
		    $i++;
		    if ($i < scalar(@$res)) {
				$y_next_eight = analyze_text_height($text, $res->[$i][2], $table_params->{col3_w} - 2*$padding_col3, $font, $table_params->{font_size});
				#print ("Inner: ".$y_bottom."\t".$y_next_eight."\n");
			}
    	}
	    $gfx->move( $x0, $y_bottom );
	    $gfx->hline($x0 + $table_params->{width} );
	    $gfx->move(  $col1_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col2_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $col3_x0, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->move(  $end_vline, $y0);
	    $gfx->vline( $y_bottom );
	    $gfx->stroke;
	    
	    if ($i < scalar(@$res)) {
	    	my $new_page = $pdf->page();
		    # Retrieve an existing page
		    my $page_number;
		    $new_page = $pdf->openpage($page_number);
		    # Set the page size
		    $new_page->mediabox('A4');
		    create_header($pdf, $new_page, $patient_info, $colontitul_params_text_params);
		    $text = $new_page->text();
		    $text->font($fontbd, $header_font_size);
		    $text->translate($header_x0, $header_y0);
			$text->text("Ваш результат:");
		    #$table_params->{x0} = 20;
		    #$table_params->{y0} = 670;
		    draw_table($pdf, $new_page, $table_params, $patient_info, $colontitul_params_text_params, $res, $i, $last_gene_name);
	    }
	        


	    
	    $y_bottom -= $d;
    	
    }
    
    
    return $y_bottom;
}

sub blank_list_only_header_for_genes {
	my ($pdf, $patient_name, $patient_info, $colontitul_params_text_params) = @_;
	my $page = $pdf->page();

    # Retrieve an existing page
    my $page_number;
    $page = $pdf->openpage($page_number);

    # Set the page size
    $page->mediabox('A4');
    create_header($pdf, $page, $patient_name, $patient_info, $colontitul_params_text_params);
}

