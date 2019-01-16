require "isodoc"
require_relative "metadata"
require_relative "m3dpdfrender"
require "fileutils"

module IsoDoc
  module M3d
    # A {Converter} implementation that generates CSAND output, and a document
    # schema encapsulation of the document for validation
    class PdfConvert < IsoDoc::PdfConvert
      def add_image(filenames)
        filenames.each do |filename|
          FileUtils.cp html_doc_path(filename), filename
          @files_to_delete << filename
        end
      end

      def initialize(options)
        @libdir = File.dirname(__FILE__)
        super
      end

      def convert1(docxml, filename, dir)
        add_image(%w(logo.jpg m3-logo.png))
        super
      end

      def default_fonts(options)
        {
          bodyfont: (options[:script] == "Hans" ? '"SimSun",serif' : '"Overpass",sans-serif'),
          headerfont: (options[:script] == "Hans" ? '"SimHei",sans-serif' : '"Overpass",sans-serif'),
          monospacefont: '"Space Mono",monospace'
        }
      end

      def default_file_locations(_options)
        {
          htmlstylesheet: html_doc_path("htmlstyle.scss"),
          htmlcoverpage: html_doc_path("html_m3d_titlepage.html"),
          htmlintropage: html_doc_path("html_m3d_intro.html"),
          standardstylesheet: nil,
          scripts_pdf: html_doc_path("scripts.pdf.html"),
        }
      end

      def metadata_init(lang, script, labels)
        @meta = Metadata.new(lang, script, labels)
      end

      def colophon(body, docxml)
        body.div **{ class: "colophon" } do |div|
          div << <<~"COLOPHON"
          <p>As with all M3AAWG documents that we publish, please check the M3AAWG website
          (<a href="http://www.m3aawg.org">www.m3aawg.org</a>) for updates to this paper.</p>
          <p>&copy; {{ docyear }} copyright by the Messaging, Malware and Mobile Anti-Abuse Working Group (M3AAWG)</p>
          COLOPHON
        end
      end

      def html_head()
        <<~HEAD.freeze
        <title>{{ doctitle }}</title>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>

    <!--TOC script import-->
    <script type="text/javascript"  src="https://cdn.rawgit.com/jgallen23/toc/0.3.2/dist/toc.min.js"></script>

    <!--Google fonts-->
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,600,600i|Space+Mono:400,700" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Overpass:300,300i,600,900" rel="stylesheet">
    <!--Font awesome import for the link icon-->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.8/css/solid.css" integrity="sha384-v2Tw72dyUXeU3y4aM2Y0tBJQkGfplr39mxZqlTBDUZAb9BGoC40+rdFCG0m10lXk" crossorigin="anonymous">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.8/css/fontawesome.css" integrity="sha384-q3jl8XQu1OpdLgGFvNRnPdj5VIlCvgsDQTQB6owSOHWlAurxul7f+JpUOVdAiJ5P" crossorigin="anonymous">
<style class="anchorjs"></style>
        HEAD
      end

      def make_body(xml, docxml)
        body_attr = { lang: "EN-US", link: "blue", vlink: "#954F72", "xml:lang": "EN-US", class: "container" }
        xml.body **body_attr do |body|
          make_body1(body, docxml)
          make_body2(body, docxml)
          make_body3(body, docxml)
          colophon(body, docxml)
        end
      end

      def html_toc(docxml)
        docxml
      end
    end
  end
end

