module VocabSheetHelper
  def vocab_sheet?
    @sheet.blank? || @sheet.items.length.zero? ? nil : 'vocab_sheet_background'
  end
end
