
use strict;
use warnings;

package RT::Action::SLA::Set;

use base qw(RT::Action::SLA);

=head1 NAME

RT::Action::SLA::Set - set default SLA value

=cut

sub Prepare { return 1 }
sub Commit {
    my $self = shift;

    my $cf = RT::CustomField->new( $self->CurrentUser );
    $cf->LoadByNameAndQueue( Queue => $self->TicketObj->Queue, Name => 'SLA' );
    unless ( $cf->id ) {
        $RT::Logger->warn("SLA scrip applied to a queue that has no SLA CF");
        return 1;
    }

    my $SLA = $self->Agreements;
    my $level = $SLA->SLA( $self->TransactionObj->CreatedObj->Unix );
    unless ( $level ) {
        if ( $SLA->IsInHours( $self->TransactionObj->CreatedObj->Unix ) ) {
            $RT::Logger->debug("No default service level for in hours time");
        } else {
            $RT::Logger->debug("No default service level for out of hours time");
        }
        return 1;
    }

    my ($status, $msg) = $self->TicketObj->AddCustomFieldValue(
        Field => $cf->id,
        Value => $level,
    );
    unless ( $status ) {
        $RT::Logger->error("Couldn't set service level: $msg");
        return 0;
    }

    return 1;
};

1;
