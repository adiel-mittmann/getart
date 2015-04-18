getart
======

A simple command line tool to fetch PDF articles from journals that you follow
using Newsbeuter.

It will read Newsbeuter's database and attempt to download all unread articles
that it recognizes are from scientific journals.  Once the PDF file has been
downloaded and stored, the article is marked as read.

Please notice that this tool does not circumvent in any way pay walls set up by
publishers.  A SOCKS proxy can be used, however.

It currently handles:

* IEEE
* Elsevier
* Springer
* Wiley
* MIT press
* World Scientific
* ACM
* Taylor and Francis
* SAGE
* IOS
* PLOS
* Liebert
* PNAS
* Nature
* Science
