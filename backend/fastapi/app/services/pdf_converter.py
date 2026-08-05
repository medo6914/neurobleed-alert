import logging

logger = logging.getLogger(__name__)


def html_to_pdf(html_content: str) -> bytes | None:
    try:
        from weasyprint import HTML

        pdf_bytes = HTML(string=html_content).write_pdf()
        return pdf_bytes
    except ImportError:
        logger.warning("weasyprint not installed, PDF conversion unavailable")
        return None
    except Exception as e:
        logger.error("PDF conversion error", exc_info=e)
        return None
