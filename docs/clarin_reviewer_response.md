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

> The screenshots are in general too small to read, pls. make them larger!

Noted, we enlarged them (and with some creative cropping) as far as possible now without getting into trouble with the
page limit. It will still be on the small side in print, but hopefully the parts that should be readible are now
readible enough.

> Figure 5 would be a lot more interesting/convincing, if you gave an example from your actualy projects, rather than 101 for programming.

We opted for this image to implicitly convey that LaMachine also has its uses in education. Showing actual development projects
would not be very meaningful to the uninformed reader.

## REVIEW 2

> The justification for such a system is well argued for but how such facility relates to other functions that CLARIN centres are
> supposed to serve is not entirely clear.

## REVIEW 4

This reviewer poses some very good and interesting questions about the relation between LaMachine and the larger CLARIN infrastructure.
It's hard to sufficiently address this in the paper in the limited space available, as we focus mostly on providing an
clear description on what LaMachine is and contains.

> Is LaMachine actively distributed and maintained at a CLARIN centre or by CLARIN ERIC centrally?

It's maintained and released by us, the Centre of Language and Speech Technology, distributed through various channels (github, docker hub, vagrant
cloud). We are in the process of becoming a certified CLARIN centre but I omitted that in the paper because I'm not sure
of our current CLARIN centre status and things are quite in state of flux so will be outdated quickly.

> Is there a global installation of LaMachine run and maintained by CLARIN and to which all CLARIN users can get access?

Yes, good point. There is our installation at https://webservices-lst.science.ru.nl , which exposes at least various
higher-level interfaces (low-level shell access and Jupyter Lab access would be a security risk of course). I added a
mention of this in the paper because it was indeed missing.

> If so, is this installation accessible through login with the CLARIN ID federation?

Not yet, we keep getting contradicting signals whether this is desired and are running into the issue that CLARIN(-NL) (to my
limited understainding) does not yet seem to have the relevant OAuth infrastructure in place that allows single-sign-on
also with RESTful webservices (the delegation problem). We do have a remark in the paper that this is a point of future
work.

> The paper states "Support for macOS is limited because not all participating software supports it." Could it be a solution to containerize such
> software?

One of LaMachine's flavours provides a container solution (n.b: a single container for all selected software). But on
macOS containerisation often implies virtualisation, which in fact is also already provided by LaMachine as another
flavour. That indeed offers a viable way to use software in LaMachine that is not otherwise possible on macOS (or
Windows for that matter). The statement about limited support, however, applied to compiling software for macOS
natively. I added a small footnote to hopefully clarify this.

> Is LaMachine catalogued in the VLO, with a PID to the metadata?

No, nobody has ever requested this desire yet. I'll look into it. It may be a bit difficult as LaMachine is such a
meta-distribution that it is hard to pin down for any single scenario, but it would be interesting for the services
inside a LaMachine installation.  I opened issue https://github.com/proycon/LaMachine/issues/138 to this end. It's not
in the paper as it does not offer sufficient space for such a discussion.

> Does LaMachine aim at compatibility with the CLARIN Language Resource Switchboard? The paper states that LaMachine "transcends" the
> ambitions of the Switchboard, but more relevant is the question whether the two are compatible and can be integrated.

The "transcends" remark in our paper applies to the VRE project rather than to LaMachine, I clarified it to prevent
confusion. LaMachine is not directly comparable with the switchboard as it offers no switchboard functionality. Now, the
switchboard itself could possibly be included in the LaMachine distribution. I briefly considered this but decided to
include a simpler portal instead as the switchboard did not meet all our demands and other initiatives were started to
compete with it (CLARIAH WP3 VRE). Tighter compatibility between the switchboard and services offered by a LaMachine
installation would be possible, but this is more a question for the switchboard developers than for us.

In fact, the current switchboard already points to various webservices that are hosted in our LaMachine installation at
Radboud University, though this involved manual duplication of metadata rather than leveraging the codemeta we offer.

> Does LaMachine support and expose CMDI metadata for the data it processes? It seems that only CodeMeta is supported, which I do not
> believe to be a CLARIN standard. Why not CMDI?

LaMachine itself is a distribution so it doesn't process any data as such; that would be a question for particular tools
or frameworks and would not be something we as a distribution would enforce either.

As to CodeMeta for software metadata, we tried to clarify our choice for that in the section titled 'Metadata'. We do hope we can come
to a synthesis with CMDI software descriptions and there are actually some ongoing discussions to that end.


