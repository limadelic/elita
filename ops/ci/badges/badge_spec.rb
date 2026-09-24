require_relative 'badge'

describe Badge do
  describe '.lint' do
    it 'returns markdown link with lint badge' do
      url = 'https://example.com/lint'
      allow(ENV).to receive(:fetch).with('LINT_URL').and_return(url)

      result = Badge.lint
      expect(result).to include('[![lint]')
      expect(result).to include(url)
      expect(result).to include('actions/workflows/lint.yml')
    end
  end

  describe '.cukes' do
    it 'returns markdown link with cukes badge' do
      pr = '42'
      url = 'https://example.com/cukes'
      allow(ENV).to receive(:fetch).with('PR_NUMBER').and_return(pr)
      allow(ENV).to receive(:fetch).with('CUKES_URL').and_return(url)

      result = Badge.cukes
      expect(result).to include('[![cukes]')
      expect(result).to include(url)
      expect(result).to include("https://limadelic.github.io/elita/#{pr}/report.html")
    end
  end

  describe '.cover' do
    it 'returns markdown link with cover badge' do
      pr = '42'
      url = 'https://example.com/cover'
      allow(ENV).to receive(:fetch).with('PR_NUMBER').and_return(pr)
      allow(ENV).to receive(:fetch).with('COVER_URL').and_return(url)

      result = Badge.cover
      expect(result).to include('[![cover]')
      expect(result).to include(url)
      expect(result).to include("https://limadelic.github.io/elita/#{pr}/cover/index.html")
    end
  end

  describe '.freeq' do
    it 'returns markdown link with freeq badge' do
      pr = '42'
      url = 'https://example.com/freeq'
      allow(ENV).to receive(:fetch).with('PR_NUMBER').and_return(pr)
      allow(ENV).to receive(:fetch).with('FREEQ_URL').and_return(url)

      result = Badge.freeq
      expect(result).to include('[![freeq]')
      expect(result).to include(url)
      expect(result).to include("https://limadelic.github.io/elita/#{pr}/freeq.webm")
    end
  end

  describe '.block' do
    it 'includes all badge methods' do
      pr = '42'
      lint_url = 'https://example.com/lint'
      cukes_url = 'https://example.com/cukes'
      cover_url = 'https://example.com/cover'
      freeq_url = 'https://example.com/freeq'

      allow(ENV).to receive(:fetch).with('LINT_URL').and_return(lint_url)
      allow(ENV).to receive(:fetch).with('PR_NUMBER').and_return(pr)
      allow(ENV).to receive(:fetch).with('CUKES_URL').and_return(cukes_url)
      allow(ENV).to receive(:fetch).with('COVER_URL').and_return(cover_url)
      allow(ENV).to receive(:fetch).with('FREEQ_URL').and_return(freeq_url)

      result = Badge.block
      expect(result).to include('<!-- badges-start -->')
      expect(result).to include('<!-- badges-end -->')
      expect(result).to include('[![lint]')
      expect(result).to include('[![cukes]')
      expect(result).to include('[![cover]')
      expect(result).to include('[![freeq]')
    end
  end

  describe '.append' do
    it 'appends badge block to content' do
      pr = '42'
      content = 'Some PR description'
      lint_url = 'https://example.com/lint'
      cukes_url = 'https://example.com/cukes'
      cover_url = 'https://example.com/cover'
      freeq_url = 'https://example.com/freeq'

      allow(ENV).to receive(:fetch).with('LINT_URL').and_return(lint_url)
      allow(ENV).to receive(:fetch).with('PR_NUMBER').and_return(pr)
      allow(ENV).to receive(:fetch).with('CUKES_URL').and_return(cukes_url)
      allow(ENV).to receive(:fetch).with('COVER_URL').and_return(cover_url)
      allow(ENV).to receive(:fetch).with('FREEQ_URL').and_return(freeq_url)

      result = Badge.append(content)
      expect(result).to start_with(content)
      expect(result).to include('<!-- badges-start -->')
      expect(result).to include('[![freeq]')
    end
  end
end
