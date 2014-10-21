#
# Net::SMS::TMobile::UK . This module allows the sending of SMS Text Messages via
# the T-Mobile UK Website. 
#
# Author: Ben Charlton <ben@spod.cx>
#
# Copyright (c) 2007 Ben Charlton. All Rights Reserved. 
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Net::SMS::TMobile::UK;

our $VERSION = '0.01';

use strict;
use HTTP::Request::Common qw(POST GET);
use LWP::UserAgent;

=head1 NAME

Net::SMS::TMobile::UK - Send SMS Messages via the T-Mobile UK Website.

=head1 SYNOPSIS

  use Net::SMS::TMobile::UK;

  my $sms = Net::SMS::TMobile::UK->new(username=>$username, password=>$password);
  $sms->sendsms(to=>$target, message=>$message);

=head1 DESCRIPTION

T-Mobile is a major mobile network. Their UK Website allows the sending of 'webtext' 
messages which are an SMS sent from the users mobile number and charged against their
mobile phone account. This module allows the sending of these messages - ideal if you
pay for a bundle of SMS messages in advance. 

Please note that this module is nothing to do with T-Mobile, and will probably stop 
working should T-Mobile ever change the method for sms submission.

=head1 METHODS

=head2 new

Creates the Net::SMS::TMobile::UK object.

Usage:

  my $sms = Net::SMS::TMobile::UK->new (username=>$username, password=>$password);

The complete list of arguments is:

  username  : Your registered T-Mobile username.
  password  : Your registered T-Mobile password.
  useragent : Name of the user agent you want to display to T-Mobile.

=cut

sub new {
	my $class = shift;
	unless ($class) {
		return undef;
	}

	my %args = ( 
		useragent=>'TMobileUK.pm/'.$Net::SMS::TMobile::UK::VERSION,
		@_ );

	unless ($args{username}) {
		return undef;
	}
	unless ($args{password}) {
		return undef;
	}

	my $ua = LWP::UserAgent->new();
	$ua->cookie_jar( {} );

	return bless { PASSWORD=>$args{password},
			USERNAME=>$args{username},
			USERAGENT=>$args{useragent},
			ERROR=>0,
			LWP_UA=>$ua
		}, $class; 
}


=head2 sendsms

Sends a message through the T-Mobile website.

Usage:

  $sms->sendsms( to => $mobile_phone, message => $msg );

where $mobile_phone is the mobile phone number that you're sending a 
message to and $msg is the message text.

This method returns 1 if we successfully send the message and undef on failure.

=cut

sub sendsms () {
	my $self = shift;
	my %args = ( @_ );
	
	my $ua = $self->{LWP_UA};
	$ua->agent($self->{USERAGENT});

	my $target=$args{to};
	my $message=$args{message};

	## Check we have a target and message
	unless ($target && $message) {
		$self->error(5);
		return undef;
	}


	## Log in and get a session cookie
	my $req = POST 'https://www.t-mobile.co.uk:443/eservice/mtmUserLoginDispatch.do',
	   [ username=>$self->{USERNAME},
	   password=>$self->{PASSWORD},
	   submit=>"Login"];

	my $res = $ua->request($req);

	## Check for successful request
	unless ($res->is_redirect) {
		$self->error(3);
		return undef;
	}


	my $content = $res->as_string;

	## should return a redirect to  https://www.t-mobile.co.uk/eservice/private/landing.do
	## If not, assume invalid credentials. 
	unless ($content =~ m/private\/landing\.do/) {
		$self->error(2);
		return undef;
	}


	## Collect struts token for SMS form submission:
	$req = GET 'https://www.t-mobile.co.uk:443/eservice/private/sendTextPreparing.do';
	$res = $ua->request($req);
	unless ($res->is_success) {
		$self->error(3);
		return undef;
	}
	$content = $res->as_string;
	my ($token) = ($content =~ m/<input type="hidden" name="org.apache.struts.taglib.html.TOKEN" value="([^"]+)">/is);

	unless ($token) {
		$self->error(4);
		return undef;
	}

	## Post to SMS sending form with message details and struts token.
	$req = POST 'https://www.t-mobile.co.uk:443/eservice/private/sendTextProcessing.do',
		[ 'org.apache.struts.taglib.html.TOKEN'=>$token,
		'recipients'=>$target,
		'message'=>$message,
		'submit'=>'Send' ];

	$res = $ua->request($req);
	unless ($res->is_success) {
		$self->error(3);
		return undef;
	}
	$content = $res->as_string;

	## Check for success
	if ($content =~ m/Success/is) {
		return 1;
	} else {
		$self->error(4);
		return undef;
	}
}

=head2 error

Returns a code that describes the last error ocurred.

Example:

  if(my $error = $sms->error) {
    if($error == 5) {
      die("Message or Destination missing\n");
    } elseif ($error == 2) {
      die("Username or password invalid\n");
    } else {
      die("Unexpected fault\n");
    }
  }

Using same error codes as Net::SMS::Clickatell where possible:

  0 - No error
  1 - Username or password not defined (not used, as we require these during module construction)
  2 - Username or password wrong
  3 - Server has problems
  4 - The message couldn't be sent
  5 - No message or destination specified

=cut

sub error {
	my $self = shift;
	if(!defined $self) {
		return undef;
	}

	my $error = shift;
	if(!defined $error) {
		return $self->{ERROR};
	} else {
		$self->{ERROR} = $error;
		return 1;
	}
}

=head1 AUTHOR

Ben Charlton, C<< <benc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-sms-tmobile-uk at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-TMobile-UK>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::TMobile::UK

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-TMobile-UK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-TMobile-UK>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-TMobile-UK>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-TMobile-UK>

=back

=head1 ACKNOWLEDGEMENTS

Net:SMS::Clickatell by Roberto Alamos Moreno for inspiration.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2007 Ben Charlton. All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This software or the author aren't related to T-Mobile in any way.

=cut

1;
