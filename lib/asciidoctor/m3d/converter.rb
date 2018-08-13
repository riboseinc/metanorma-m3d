require "asciidoctor"
require "asciidoctor/m3d/version"
require "isodoc/m3d/m3dhtmlconvert"
require "isodoc/m3d/m3dwordconvert"
require "asciidoctor/iso/converter"

module Asciidoctor
  module M3d
    M3D_NAMESPACE = "https://open.ribose.com/standards/m3d"

    # A {Converter} implementation that generates M3D output, and a document
    # schema encapsulation of the document for validation
    class Converter < ISO::Converter

      register_for "m3d"

      def metadata(node, xml)
        title node, xml
        metadata_source(node, xml)
        metadata_id(node, xml)
        metadata_author(node, xml)
        metadata_publisher(node, xml)
        xml.language node.attr("language")
        xml.script (node.attr("script") || "Latn")
        metadata_status(node, xml)
        metadata_copyright(node, xml)
        metadata_committee(node, xml)
        metadata_ics(node, xml)
      end

      def metadata_source(node, xml)
        return unless node.attr("url")
        xml.source node.attr("url")
      end

      def metadata_author(node, xml)
        xml.contributor do |c|
          c.role **{ type: "author" }
          c.organization do |a|
            a.name "Ribose"
          end
        end
      end

      def metadata_publisher(node, xml)
        xml.contributor do |c|
          c.role **{ type: "publisher" }
          c.organization do |a|
            a.name "Ribose"
          end
        end
      end

      def metadata_committee(node, xml)
        xml.editorialgroup do |a|
          a.committee node.attr("technical-committee"),
            **attr_code(type: node.attr("technical-committee-type"))
        end
      end

      def title(node, xml)
        ["en"].each do |lang|
          xml.title **{ language: lang, format: "plain" } do |t|
            t << asciidoc_sub(node.attr("title"))
          end
        end
      end

      def metadata_status(node, xml)
        xml.status(**{ format: "plain" }) { |s| s << node.attr("status") }
      end

      def metadata_id(node, xml)
        xml.docidentifier { |i| i << node.attr("docnumber") }
      end

      def metadata_copyright(node, xml)
        from = node.attr("copyright-year") || Date.today.year
        xml.copyright do |c|
          c.from from
          c.owner do |owner|
            owner.organization do |o|
              o.name "Ribose"
            end
          end
        end
      end

      def title_validate(root)
        nil
      end

      def makexml(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>\n<m3d-standard>"]
        @draft = node.attributes.has_key?("draft")
        result << noko { |ixml| front node, ixml }
        result << noko { |ixml| middle node, ixml }
        result << "</m3d-standard>"
        result = textcleanup(result.flatten * "\n")
        ret1 = cleanup(Nokogiri::XML(result))
        validate(ret1)
        ret1.root.add_namespace(nil, M3D_NAMESPACE)
        ret1
      end

      def doctype(node)
        d = node.attr("doctype")
        unless %w{policy best-practices supporting-document report}.include? d
          warn "#{d} is not a legal document type: reverting to 'report'"
          d = "report"
        end
        d
      end

      def document(node)
        init(node)
        ret1 = makexml(node)
        ret = ret1.to_xml(indent: 2)
        unless node.attr("nodoc") || !node.attr("docfile")
          filename = node.attr("docfile").gsub(/\.adoc/, ".xml").
            gsub(%r{^.*/}, "")
          File.open(filename, "w") { |f| f.write(ret) }
          html_converter(node).convert filename unless node.attr("nodoc")
          word_converter(node).convert filename unless node.attr("nodoc")
        end
        @files_to_delete.each { |f| system "rm #{f}" }
        ret
      end

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "m3d.rng"))
      end

      def literal(node)
        noko do |xml|
          xml.figure **id_attr(node) do |f|
            figure_title(node, f)
            f.pre node.lines.join("\n")
          end
        end
      end

      def sections_cleanup(x)
        super
        x.xpath("//*[@inline-header]").each do |h|
          h.delete("inline-header")
        end
      end

      def style(n, t)
        return
      end

      def html_converter(node)
        IsoDoc::M3d::HtmlConvert.new(
          script: node.attr("script"),
          bodyfont: node.attr("body-font"),
          headerfont: node.attr("header-font"),
          monospacefont: node.attr("monospace-font"),
          titlefont: node.attr("title-font"),
          i18nyaml: node.attr("i18nyaml"),
          scope: node.attr("scope"),
          htmlstylesheet: node.attr("htmlstylesheet"),
          htmlcoverpage: node.attr("htmlcoverpage"),
          htmlintropage: node.attr("htmlintropage"),
          scripts: node.attr("scripts"),
        )
      end

      def word_converter(node)
        IsoDoc::M3d::WordConvert.new(
          script: node.attr("script"),
          bodyfont: node.attr("body-font"),
          headerfont: node.attr("header-font"),
          monospacefont: node.attr("monospace-font"),
          titlefont: node.attr("title-font"),
          i18nyaml: node.attr("i18nyaml"),
          scope: node.attr("scope"),
          wordstylesheet: node.attr("wordstylesheet"),
          standardstylesheet: node.attr("standardstylesheet"),
          header: node.attr("header"),
          wordcoverpage: node.attr("wordcoverpage"),
          wordintropage: node.attr("wordintropage"),
          ulstyle: node.attr("ulstyle"),
          olstyle: node.attr("olstyle"),
        )
      end

      def inline_quoted(node)
        noko do |xml|
          case node.type
          when :emphasis then xml.em node.text
          when :strong then xml.strong node.text
          when :monospaced then xml.tt node.text
          when :double then xml << "\"#{node.text}\""
          when :single then xml << "'#{node.text}'"
          when :superscript then xml.sup node.text
          when :subscript then xml.sub node.text
          when :asciimath then stem_parse(node.text, xml)
          else
            case node.role
            when "strike" then xml.strike node.text
            when "smallcap" then xml.smallcap node.text
            when "keyword" then xml.keyword node.text
            else
              xml << node.text
            end
          end
        end.join
      end
    end
  end
end
