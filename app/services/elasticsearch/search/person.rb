class Elasticsearch::Search::Person < Elasticsearch::Search::SearchBase
  method_object [:phrase, :limit, :is_mangaka, :is_seyu, :is_producer]

private

  def query
    {
      bool: {
        should: fields_queries,
        must: [mangaka_query, seyu_query, producer_query].compact
      }
    }
  end

  def mangaka_query
    { term: { is_mangaka: true } } if @is_mangaka
  end

  def seyu_query
    { term: { is_seyu: true } } if @is_seyu
  end

  def producer_query
    { term: { is_producer: true } } if @is_producer
  end

  def cache_key
    super + [@is_mangaka, @is_seyu, @is_producer]
  end
end
