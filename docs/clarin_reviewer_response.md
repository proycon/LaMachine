## REVIEW 1

> The second point is that the impression is that the only person that would in fact be able to (or, at least, has done it so far) install
> LaMachine is the author.

On the contrary! The whole idea behind LaMachine is to facilitate installation by other parties, and there are many
users who have installed and are using LaMachine. If only we as developers succeeded in installation then that would indeed
be a major failure on our part. I added a paragraph to prevent confusion in this regard.

> Also, and at least in further work: currenlty, the already ingested software seems to cater (almost) only for Dutch.

A lot of the software is generically applicable actually. It is only CLARIN-NL/CLARIAH software like Frog, Alpino, Valkuil
and Oersetter that is very strongly focussed on Dutch. But even in those situations the underlying software often allows
for multiple languages if somebody trains models for it.

> I can see the objection that everyone can install whetever they wish,

That not an objection from our side, that's in fact deliberately what we aim for  ;)

## REVIEW 2

> The justification for such a system is well argued for but how such facility relates to other functions that CLARIN centres are
> supposed to serve is not entirely clear.

## REVIEW 4

This reviewer poses some very good and interesting questions about the relation between LaMachine and the larger CLARIN infrastructure:

> Is LaMachine actively distributed and maintained at a CLARIN centre or by CLARIN ERIC centrally?

It's distributed by the Centre of Language and Speech Technology, who are in the process of becoming a certified CLARIN
centre but are not yet one at this moment, no.

> Is there a global installation of LaMachine run and maintained by CLARIN and to which all CLARIN users can get access?

There is our installation at https://webservices-lst.science.ru.nl .

> If so, is this installation accessible through login with the CLARIN ID federation?

Not yet, we keep getting contradicting signals whether this is desired and are running into the issue that CLARIN(-NL) (to my
limited understainding) does not yet seem to have the relevant OAuth infrastructure in place that allows single-sign-on
also with RESTful webservices (the delegation problem).

> The paper states "Support for macOS is limited because not all participating software supports it." Could it be a solution to containerize such
> software?

One of LaMachine's flavours provides a container solution (n.b: a single container for all selected software). But on
macOS containerisation often implies virtualisation, which in fact is also already provided by LaMachine as another
flavour. That indeed offers a viable way to use software in LaMachine that is not otherwise possible on macOS (or
Windows for that matter). The statement about limited support, however, applied to compiling software for macOS
natively. I added a small footnote to hopefully clarify this.

> Is LaMachine catalogued in the VLO, with a PID to the metadata?

No, nobody has ever requested this desire yet. I'll look into it. It may be a bit difficult as LaMachine is such a
meta-distribution that it is hard to pin down for any single scenario.

> Does LaMachine aim at compatibility with the CLARIN Language Resource Switchboard? The paper states that LaMachine "transcends" the
> ambitions of the Switchboard, but more relevant is the question whether the two are compatible and can be integrated.

That remark in our paper applies to the VRE project rather than to LaMachine, I clarified it to prevent confusion. LaMachine is not directly comparable with the
switchboard as it offers no switchboard functionality. Now, the switchboard itself possibly be included in the LaMachine
distribution. I briefly considered this but decided to include a simpler portal instead as the switchboard did not meet
all our demands and other initiatives were started to compete with it (CLARIAH WP3 VRE). Tighter compatibility between
the switchboard and services offered by a LaMachine installation would be possible, but this is more a question for the
switchboard developers than for us.

In fact, the current switchboard already points to various webservices that are hosted in our LaMachine installation at
Radboud University, though this involved manual duplication of metadata rather than leveraging the codemeta we offer.

