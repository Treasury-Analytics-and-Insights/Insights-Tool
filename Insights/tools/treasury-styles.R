treasury_header = function() div(
  div(
    # tags$a(href = "http://www.treasury.govt.nz/",
    #        title = "Treasury NZ",
    #        tags$img(src = "img/treasury-banner-new.png",
    #                 alt = "Treasury NZ",
    #                 width = "1740px",
    #                 height = "181px"))
    class = "banner",
    # tags$a(
    #   href = "#",
    #   title = "Treasury NZ",
    #   direct_to = "Home",
    #   tags$img(src = "img/treasury-banner-new.png",
    #           alt = "Treasury NZ",
    #           width = "1740px",
    #           height = "181px")
    #   )
    # div(
    #   style="background:url(img/treasury-banner-new.png); background-size: 100% 120px;
    # background-repeat: no-repeat",
    #   tags$a(
    #     href = "http://www.treasury.govt.nz/",
    #     title="Treasury NZ",
    #     tags$img(
    #       src="img/insights-logo.png",
    #       alt="Treasury NZ",
    #       width="350",
    #       height="121"
    #     )
    #   )
    # )
    div(
      style="background:url(img/treasury-banner-new.png); background-size: 100% 120px;
      background-repeat: no-repeat",
      tags$a(
        href = "#",
        title="Treasury NZ",
        direct_to = "Home",
        tags$img(
          src="img/insights-logo.png",
          alt="Treasury NZ",
          width="350",
          height="121"
        )
      )
    )
  )
)

treasury_about = function() tabPanel(
  "About",
  div(
    column(
      width = 2
    ),
    column(
      width = 8,
      fluidRow(
        tags$p(
          strong("Insights"),
          " was developed by the New Zealand Treasury's Analytics and Insights team with the help of",
          tags$a(
            href = "http://www.harmonic.co.nz/",
            "Harmonic Analytics Limited"
          ),
          ", using data from Stats NZ's Integrated Data Infrastructure (IDI). ",
          strong("Insights"),
          "is hosted by ",
          tags$a(
            href = "http://catalyst.net.nz/",
            "Catalyst"
          ),
          ". All information shown in ",
          strong("Insights"),
          " is anonymous. IDI data is held in a secure environment and made available to researchers under strict conditions. The analysis is protected by Stats NZ rules to ensure that no individual can be identified."
        )
      ),
      fluidRow(
        tags$p(
          "This work is part of the Treasury's commitment to higher living standards and a more prosperous, inclusive New Zealand. Insights was designed to inform effective policies and services through better information. ",
          strong("Insights"),
          " currently presents information about risk, outcomes, and service use for children aged 0 to 14, and youth aged 15 to 24 in New Zealand. Over time ",
          strong("Insights"),
          " will be developed to include information on the lives of all New Zealanders. "
        )
      ),
      fluidRow(
        tags$p(
          "The results are based on an estimated New Zealand resident population, as outlined in ",
          tags$a(
            href = "http://www.stats.govt.nz/methods/research-papers/topss/identifying-nz-resident-pop-in-idi/discussion.aspx",
            "Identifying the New Zealand resident population in the Integrated Data Infrastructure"
          ),
          ", and are as at the end of December each year. Temporary migrants such as international students and working holidaymakers are excluded from the results, as we have limited data about their past, and they are not eligible for many services."
        )
      ),
      fluidRow(
        tags$p(
          "Many results are presented by gender and by ethnicity.  Ethnicity is collected by a number of agencies, but in this work we use the Ministry of Health classification. Results are mapped geographically according to people's residential address. This is based on addresses collected by a number of agencies, but in some cases may be out of date or inaccurate. The quality of geographic information in the IDI is discussed in ",
          tags$a(
            href = "http://www.stats.govt.nz/methods/research-papers/topss/quality-geo-info-idi/results.aspx",
            "Quality of geographic information in the Integrated Data Infrastructure."
          )
        )
      ),
      fluidRow(
        tags$p(
          "The data presented in ",
          strong("Insights"),
          " was developed by linking administrative information across government agencies. The data will not always be accurate, particularly when presented at a very detailed level. In some cases information for one person may be incorrectly linked to information for a different person. The linking process is described at ",
          tags$a(
            href = "http://www.stats.govt.nz/browse_for_stats/snapshots-of-nz/integrated-data-infrastructure/idi-resources.aspx",
            "Resources for IDI users"
          ),
          " along with other technical information. While the results highlight the power of using integrated administrative data in new and innovative ways, some of the methods are exploratory in nature. Caution should be taken in interpreting the results of any detailed analysis undertaken using ",
          strong("Insights."),
          "Counts have been randomly rounded to base 3 and small counts suppressed (replaced with an s) to protect confidentiality."
        )
      ),
      fluidRow(
        tags$p(
          "For more detailed information about ",
          strong("Insights"),
          " and the data behind it see ",
          tags$a(
            href = "http://www.treasury.govt.nz/publications/research-policy/ap/2017/17-02",
            "Insights - informing policies and services for at-risk children and youth"
          ),
          "or contact ",
          tags$a(
            href = "mailto:insights@treasury.govt.nz",
            "insights@treasury.govt.nz"
          ),
          "."
        )
      ),
      br(),
      fluidRow(
        tags$p(
          strong("Disclaimer: "),
          "Access to the data presented was managed by Statistics New Zealand under strict micro-data access protocols and in accordance with the security and confidentiality provisions of the Statistics Act 1975. These findings are not Official Statistics. The opinions, findings, recommendations, and conclusions expressed are not those of Statistics New Zealand."
        )
      ),
      fluidRow(
        tags$p(
          strong("Google Analytics: "),
          "This site also uses Google Analytics, a web analytics service provided by Google Inc. Google Analytics uses cookies. The information generated by the cookie about your use of the site is transmitted to, and stored by Google on servers in the United States. Google uses this information for the purpose of evaluating how you use this site, compiling reports on site activity, and providing other services relating to site activity and internet usage. Google may also transfer this information to third parties where required to do so by law, or where such third parties process the information on Google's behalf. Google will not associate your IP address with any other data held by Google. When you use this site you consent to the processing of data about you by Google, in the manner and for the purposes set out above."
        )
      ),
      fluidRow(
        id = "copyright",
        p(strong("Copyright and licensing: ")),
        br(),
        p(HTML("&copy; Crown Copyright")),
        br(),
        p("Copyright material on this Insights site is protected by copyright owned by the New Zealand Treasury on behalf of the Crown."),
        br(),
        p(
          "This work is licensed under the ,",
          tags$a(
            href = "https://creativecommons.org/licenses/by/4.0/",
            "Creative Commons Attribution 4.0 International licence"
          ),
          ". You are free to copy, distribute, and adapt the work, as long as you attribute the work to New Zealand Treasury and abide by the other licence terms. Please note you may not use any departmental or governmental emblem, logo, or coat of arms in any way that infringes any provision of the Flags, Emblems, and Names Protection Act 1981. Use the wording 'New Zealand Treasury' in your attribution, not the relevant logo."
        )
      )
    )
  )
)

treasury_contact = function() tabPanel(
  "Contact",
  id = "contact_tab",
  div(
    column(
      width = 2
    ),
    column(
      width = 8,
      fluidRow(
        h3(strong("Insights")," was created by Treasury's Analytics and Insights team, with the help of Harmonic Analytics, using data from Statistics NZ's Integrated Data Infrastructure."),
        br(),
        h3("The Analytics and Insights team undertakes analysis to inform evidence based policy and practice, supporting: "),
        tags$ul(
            tags$li("The Treasury's strategic priorities by undertaking relevant research and analysis"),
            tags$li("The social sector to generate better evidence on cross-sector impacts"),
            tags$li("The development and use of the Integrated Data Infrastructure.")
        ),
        br(),
        h3("Analytics and Insights - The Treasury"),
        tags$p("1 The Terrace, Wellington 6011, New Zealand "),
        tags$p("PO Box 3724, Wellington 6140, New Zealand "),
        tags$p("Tel: +64 4 472 2733  Fax: +64 4 473 0982"),
        br(),
        p(
          "If you have any questions, comments or suggestions contact us at: ",
          tags$a(
            href = "mailto:insights@treasury.govt.nz",
            "insights@treasury.govt.nz"
          )
        )
      )
    )
  )
)

treasury_privacy = function() tabPanel(
  "Privacy",
  id = "privacy_tab",
  div(
    column(
      width = 1
    ),
    column(
      width = 10,
      fluidRow(
        h4("Purpose"),
        strong("1. Purpose"),
        p('The purpose of this privacy policy is to let users of insights.apps.treasury.govt.nz (the "Site") know when we collect personal information and what we do with it. We do not use, share or transfer personal information in connection with the Site except as set out in this policy.'),
        h4("Collection, storage and use"),
        strong("2. No need to disclose personal information"),
        p("The Site can be viewed without the need to disclose any personal information to us."),
        strong("3. Your disclosure of personal information"),
        p('However, you may choose to disclose personal information when adding material to the Site. Such information will be viewable by Site administrators, certain Treasury  staff and contractors (including third parties providing services related to the administration, improvement, and/or securing of the Site and the information it contains ("Third Party Contractors")) and, if published, members of the public. Please do not post or otherwise transmit personal information of a sensitive nature.'),
        strong("4. Holding of information"),
        p("Information (including personal information) that you provide to Treasury in electronic form will be held by the Treasury, and may be shared with, and held by, Third Party Contractors to the extent necessary for the services they provide related to the administration, improvement, and/or securing of the Treasury's ICT systems, the Site, and the information the Site contains. Email addresses provided when commenting in the discussion forum or other areas of the Site or when emailing feedback directly to the Treasury are not made available to the public. Unless required by law, we will not publicise the names or email addresses of individuals who provide feedback to us without their consent."),
        strong('5. Use of personal information'),
        p('We will only use personal information provided to us for the purposes of administering, evaluating, improving, and securing the Site and the information it contains, improving our services and communicating with you.'),
        strong('6. Feedback'),
        p('Feedback is important and is used to evaluate and improve the Site. If you provide feedback on the Site directly to the Treasury via the supplied email address, that feedback will be sent to appropriate Treasury staff. We may pass on relevant comments to other people within the Treasury who administer, have contributed content to, or are otherwise interested in, the Site. This could include your email address and other identifying information.'),
        h4('Statistical information and cookies'),
        strong('7. Statistical information collected'),
        p('We may collect statistical information about your visit to help us improve the Site. We use Google Analytics for tracking usage of the Site. This information is aggregated and non-personally identifying. It includes:'),
        tags$ul(
           tags$li('your IP address;'),
           tags$li('the search terms you used;'),
           tags$li('the pages you accessed on our Site and the links you clicked on;'),
           tags$li('the date and time you visited the site;'),
           tags$li('the referring site (if any) through which you clicked through to this Site;'),
           tags$li('your operating system (e.g., Windows XP, Mac OS X); '),
           tags$li('the type of web browser you use (e.g. Internet Explorer, Mozilla Firefox); and'),
           tags$li('other incidental matters such as screen resolution and the language setting of your browser.')
           ),
        strong('8. Use of statistical information'),
        p('The statistical information referred to above will be viewable by Site administrators and certain other Treasury staff. It may also be shared with other government agencies.'),
        strong('9. Cookies'),
        p('This Site generates persistent session cookies for the purpose of monitoring Site usage. The cookies do not collect personal information. You can disable them or clear them out of the web browser you are using to view this Site without affecting your ability to use the Site.'),
        h4('Records and disclosure statement'),
        strong('10. Public Records, Official Information and Parliament'),
        p('Your emails and contributions to the Site may constitute public records and be retained to the extent required by the Public Records Act 2005. The Treasury may also be required to disclose those materials under the Official Information Act 1982 or to a Parliamentary Select Committee or Parliament in response to a Parliamentary Question.'),
        h4('Rights of access and correction '),
        strong('11. Your rights'),
        p('Under the Privacy Act 1993, you have the right to access and to request correction of any of your personal information provided to the Treasury in connection with your use of this Site. If you would like to see the personal information relating to you that the Treasury has stored, or to change such personal information, or if you have any concerns regarding your privacy, please contact us at the address set out below. The Treasury may require proof of your identity before being able to provide you with any personal information.'),
        h4("Privacy Officer "),
        p("The Treasury"),
        p("PO Box 3724"),
        p("Wellington 6140"),
        p(
          "Email: ",
          tags$a(
            href = "mailto:privacy@treasury.govt.nz",
            "privacy@treasury.govt.nz"
          )
        ),
        p("Tel: +64 4 472 2733 "),
        p("Fax: +64 4 473 0982 "),
        strong("12. Privacy Commissioner"),
        p("If you are not satisfied with our response to any privacy-related concern you may have, you can contact the Privacy Commissioner: "),
        h4("Office of the Privacy Commissioner"),
        p("PO Box 10-094"),
        p("Wellington, New Zealand"),
        p("Tel: +64 4 474 7590"),
        p("Enquiries Line (from Auckland): 302 8655"),
        p("Enquiries Line (from outside Auckland): 0800 803 909"),
        p("Fax: +64 4 474 7595"),
        p(
          "Email: ",
          tags$a(
            href = "mailto:enquiries@privacy.org.nz",
            "enquiries@privacy.org.nz"
          )
        )
      )
    )
  )
)

treasury_footer = function() {
  div(
    style = "padding-top: 100px;",
    tags$footer(
      align = "centre", 
      style = "position:relative;
      bottom:0;
      width:100%;
      /*height:160px;  Height of the footer */
      display:inline-block;
      color: white;
      padding: 10px;
      background-color: #e6e6e6;
      z-index: 1000;",
      div(
        class = "footer-left",
        style = "float: left; /*padding-left: 50px;*/",
        tags$a(
          href = "http://www.treasury.govt.nz/",
          title = "Treasury NZ",
          tags$img(
            src = "img/treasury-logo-new.png",
            alt = "Treasury NZ",
            width = "356px",
            height = "120px"
          )
        )
      ),
      div(
        class = "footer-statsnz",
        style = "float: right; padding-top: 40px;",
        tags$a(
          href = "http://www.stats.govt.nz/",
          title = "Stats NZ",
          tags$img(
            src = "img/statsnz_logo.png",
            alt = "Stats NZ",
            width = "155px",
            height = "63px"
          )
        )
      ),
      div(
        class = "footer-right",
        style = "text-align: center; float: right; padding-right: 30px; padding-top: 40px;",
        tags$a(
          href = "#",
          style = "display: inline-block;",
          direct_to = "Contact",
          tags$h6(
            style = "display: inline-block;color: #003b85;", 
            strong("Contact")
          )
        ),
        tags$span(
          style = "display: inline-block;color: #003b85;", 
          strong("|")
        ),
        tags$a(
          href = "#",
          direct_to = "About",
          tags$h6(
            style = "display: inline-block;color: #003b85;", 
            strong("Copyright and licensing")
          )
        ),
        tags$span(
          style = "display: inline-block;color: black;color: #003b85;", 
          strong("|")
        ),
        tags$a(
          href = "#",
          direct_to = "Privacy",
          tags$h6(
            style = "display: inline-block;color: #003b85;", 
            strong("Privacy")
          )
        ),
        tags$span(
          style = "display: inline-block;color: black;color: #003b85;", 
          strong("|")
        ),
        tags$a(
          href = "http://www.treasury.govt.nz/",
          tags$h6(
            style = "display: inline-block;color: #003b85;", 
            strong("The Treasury")
          )
        ),
        br(),
        tags$h6(
          style = "display: inline-block;color: #003b85;", 
          strong("Enabled by Statistics NZ.")
        ),
        tags$a(
          href = "http://www.harmonic.co.nz",
          style = "display: inline-block;", 
          tags$h6(
            style = "color: #003b85;",
            strong(" Data visualisation by Harmonic Analytics.")
          )
        )
      )
    )
,includeScript("google-analytics.js")
)
}