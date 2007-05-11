
use strict;
use warnings;

package RT::Action::SLA_SetDefault;

use base qw(RT::Action::SLA);

=head1 NAME

RT::Action::SLA::SetDefault - set default SLA value

=head1 DESCRIPTION

Sets a default level of service. Transaction's created field is used
to calculate if things happen in hours or out of. Default value then
figured from L<InHoursDefault|XXX> and L<OutOfHoursDefault|XXX> options.

This action doesn't check if the ticket has a value allready, so you
have to use it with condition that checks this fact for you, however
such behaviour allows you to force setting up default using custom
condition. The default condition for this action is
L<RT::Condition::SLA_RequireDefault>.

=cut

sub Prepare { return 1 }
sub Commit {
    my $self = shift;

    my $cf = RT::CustomField->new( $self->CurrentUser );
    $cf->LoadByNameAndQueue( Queue => $self->TicketObj->Queue, Name => 'SLA' );
    $cf->LoadByNameAndQueue( Name => 'SLA' ) unless $cf->id;
    unless ( $cf->id ) {
        $RT::Logger->warning("SLA scrip applied to a queue that has no SLA CF");
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
