<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>
<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<h3 align="center">Smart Postgres Box of Tricks</h3>

  <p align="center">
    Utility scripts to make PostgreSQL performance tuning easier.<br />
    Brought to you by the folks at <a href="https://SmartPostgres.com">SmartPostgres.com</a>.
    <br />
    <a href="https://github.com/SmartPostgres/Box-of-Tricks/issues/new?assignees=&labels=bug&projects=&template=bug_report.md&title=">Report Bug</a>
    ·
    <a href="https://github.com/SmartPostgres/Box-of-Tricks/issues/new?assignees=&labels=&projects=&template=feature_request.md&title=">Contribute Code for a Feature</a>
  </p>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>



<!-- GETTING STARTED -->
## Getting Started

Click Releases at the top of this page to download the installation file, which contains each of the sql scripts.

Our target audience is folks who already know how to create and query Postgres functions. If you don't fall into that audience, we're not quite ready for you yet, but at some point in the future we'll have more detailed instructions for folks who are completely new to Postgres.

### Prerequisites

The Box of Tricks works with all currently supported versions of Postgres (as of this writing, going back to v12), plus Amazon RDS Aurora PostgreSQL. Other proprietary cloud brands of Postgres may also work, we just haven't tested 'em. If you run into problems on other versions, we only take bug reports that also include a pull request to make the necessary changes. Otherwise, we just can't test the Box of Tricks on every possible cloud platform.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

#### check_indexes

This function analyzes the health and design of your indexes. It has 4 parameters:

<ul>
  <li>v_schema_name - default null (all schemas)</li>
  <li>v_table_name - default null (all tables)</li>
  <li>v_warning_format - default 'rows', which means each warning gets its own row. That's the only supported output format for now, but in the future we'll add a way to support multiple warnings in a single row.</li>
  <li>v_debug_level - default 0 (no debug output), can also be 1 (minimal debug output) or 2 (detailed debug output with dynamic SQL).</li>
</ul>

To check the health and design of all of the tables & indexes in your database, run:

<pre>select * from check_indexes(null, null);</pre>

Those first two parameters are schema name and table name. If you want to check all of the objects in a particular schema, run:

<pre>select * from check_indexes('my_schema_name', null)</pre>

Or to check a single table:

<pre>select * from check_indexes('my_schema_name', 'my_table_name')</pre>

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap of Upcoming Milestones

- [ ] [Version 1.1](https://github.com/SmartPostgres/Box-of-Tricks/milestone/3) - add more options for v_warning_format, add warning for server-level autovacuum changes recommended
- [ ] [Ideas for Future Features - Help Welcome](https://github.com/SmartPostgres/Box-of-Tricks/milestone/1)

See the [open issues](https://github.com/SmartPostgres/Box-of-Tricks/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request as described in our [Contributing Guide](https://github.com/SmartPostgres/Box-of-Tricks/blob/dev/CONTRIBUTING.md).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Top contributors:

<a href="https://github.com/SmartPostgres/Box-of-Tricks/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=SmartPostgres/Box-of-Tricks" alt="contrib.rocks image" />
</a>



<!-- LICENSE -->
## License

Distributed under the MIT License. [See the LICENSE file for more information.](https://github.com/SmartPostgres/Box-of-Tricks/blob/dev/LICENSE)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Brent Ozar - humans@smartpostgres.com

Project Link: [https://github.com/SmartPostgres/Box-of-Tricks](https://github.com/SmartPostgres/Box-of-Tricks)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/SmartPostgres/Box-of-Tricks.svg?style=for-the-badge
[contributors-url]: https://github.com/SmartPostgres/Box-of-Tricks/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/SmartPostgres/Box-of-Tricks.svg?style=for-the-badge
[forks-url]: https://github.com/SmartPostgres/Box-of-Tricks/network/members
[stars-shield]: https://img.shields.io/github/stars/SmartPostgres/Box-of-Tricks.svg?style=for-the-badge
[stars-url]: https://github.com/SmartPostgres/Box-of-Tricks/stargazers
[issues-shield]: https://img.shields.io/github/issues/SmartPostgres/Box-of-Tricks.svg?style=for-the-badge
[issues-url]: https://github.com/SmartPostgres/Box-of-Tricks/issues
[license-shield]: https://img.shields.io/github/license/SmartPostgres/Box-of-Tricks.svg?style=for-the-badge
[license-url]: https://github.com/SmartPostgres/Box-of-Tricks/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/brentozar
