#!perl -T

use Test::More tests => 30;
#use Test::More qw(no_plan);

BEGIN {
    use_ok ('MRS::Client');
}
diag( "Calling MRS services" );

#my $client = MRS::Client->new (host => 'localhost');
my $client = MRS::Client->new();

SKIP: {
    my $db = $client->db ('enzyme');
    eval { $db->name };
    if ($@) {
        chomp $@;
        diag ("Skipping tests requiring access to the MRS server ($@)");
        skip "No access to MRS server", 29;
    }
    ok ($db->name,                              'Databank name');
    ok ($db->version,                           'Databank version');
    ok ($db->count > -1,                        'Databank non-negative count');
    ok ($db->parser,                            'Databank parser');
    ok ($db->url,                               'Databank URL');
    can_ok ($db, 'blastable');

    ok (@{ $db->files } > 0,                      'Databank files');
    my $file = $db->files->[0];
    isa_ok ($file, 'MRS::Client::Databank::File', 'File instance');
    ok ($file->id,                                'File ID');
    ok ($file->last_modified,                     'File date');
    ok ($file->version,                           'File version');
    ok ($file->entries_count > -1,                'File non-negative count');
    ok ($file->raw_data_size > -1,                'File raw data size');
    ok ($file->file_size > -1,                    'File size');

    ok (@{ $db->indices } > 0,                     'Databank indices');
    my $index = $db->indices->[0];
    isa_ok ($index, 'MRS::Client::Databank::Index', 'Index instance');
    ok ($index->id,                                 'Index ID');
    ok ($index->description,                        'Index description');
    ok ($index->count > -1,                         'Index non-negative count');
    ok ($index->type,                               'Index type');

    my $find = $db->find ('human');
    isa_ok ($find, 'MRS::Client::Find',     'Find instance');
    ok ($find->{client} == $client,         'Find back reference');
    ok ($find->db eq $db->id,               'Find database ID');
    ok ($find->count > -1,                  'Find non-negative count');
    ok ($find->max_entries > -1,            'Find non-negative max');
    ok (@{ $find->terms } > 0,              'Find result count');
    is ($find->terms->[0], 'human',         'Find term');
    can_ok ($find, 'all_terms_required');
    can_ok ($find, 'query');

#    print STDERR $find . "\n";
};
