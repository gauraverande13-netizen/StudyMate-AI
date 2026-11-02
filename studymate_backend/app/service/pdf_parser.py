import io
import pypdf  # किंवा PyPDF2

def extract_text_from_file(file_content: bytes, filename: str) -> str:
    """PDF, DOCX किंवा TXT bytes मधून text extract करणे"""
    try:
        if isinstance(file_content, bytes):
            file_stream = io.BytesIO(file_content)
        else:
            file_stream = file_content

        filename_lower = filename.lower()

        if filename_lower.endswith(".pdf"):
            reader = pypdf.PdfReader(file_stream)
            extracted_text = []
            for page in reader.pages:
                text = page.extract_text()
                if text:
                    extracted_text.append(text)
            return "\n".join(extracted_text)

        elif filename_lower.endswith(".txt"):
            if isinstance(file_content, bytes):
                return file_content.decode("utf-8", errors="ignore")
            return str(file_content)

        elif filename_lower.endswith(".docx"):
            import docx
            doc = docx.Document(file_stream)
            return "\n".join([p.text for p in doc.paragraphs if p.text])

        else:
            return ""

    except Exception as e:
        print(f"Error reading file {filename}: {e}")
        raise ValueError(f"Failed to read file: {str(e)}")


# जुन्या इम्पोर्ट्ससाठी alias फंक्शन (जेणेकरून ImportError येणार नाही):
def extract_text_from_pdf(file_content: bytes, filename: str = "document.pdf") -> str:
    return extract_text_from_file(file_content, filename)