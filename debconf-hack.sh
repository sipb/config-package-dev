debconf_get () {
    perl -MDebconf::Db -MDebconf::Question -e '
        Debconf::Db->load(readonly => "true");
        for $label (@ARGV) {
            if ($q = Debconf::Question->get($label)) {
                print $q->owners."\t".$q->name."\t".$q->type."\t".$q->value."\t".$q->flag("seen")."\n";
            } else {
                print "\t$label\t\t\tfalse\n";
            }
        }' -- "$@"
}

debconf_set () {
    perl -MDebconf::Db -MDebconf::Template -MDebconf::Question -e '
        Debconf::Db->load;
        while (<>) {
            chomp;
            ($owners, $label, $type, $value, $seen) = split("\t");
            @o{split(", ", $owners)} = ();
            unless ($t = Debconf::Template->get($label)) {
                next unless ($owners);
                $t = Debconf::Template->new($label, $owners[0], $type);
                $t->description("Dummy template");
                $t->extended_description("This is a fake template used to pre-seed the debconf database. If you are seeing this, something is probably wrong.");
            }
            @to{split(", ", $t->owners)} = ();
            map { $t->addowner($_) unless exists $to{$_}; } keys %o;
            map { $t->removeowner($_) unless exists $o{$_}; } keys %to;
            next unless ($q = Debconf::Question->get($label));
            $q->value($value);
            $q->flag("seen", $seen);
            @qo{split(", ", $q->owners)} = ();
            map { $q->addowner($_) unless exists $qo{$_}; } keys %o;
            map { $q->removeowner($_) unless exists $o{$_}; } keys %qo;
        }
        Debconf::Db->save;'
}
