require_relative "base_convert"
require "isodoc"

module IsoDoc
  module M3d

    # A {Converter} implementation that generates HTML output, and a document
    # schema encapsulation of the document for validation
    #
    class PdfConvert < IsoDoc::XslfoPdfConvert
      def initialize(options)
        @libdir = File.dirname(__FILE__)
        super
      end

      def pdf_stylesheet(docxml)
        "m3d.report.xsl"
      end
    end
  end
end
