package de.uniko.west.splodge;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.TreeMap;
import java.util.zip.GZIPInputStream;

/**
 * SPLODGE Query Generator
 * 
 * @author Olaf Goerlitz (goerlitz@uni-koblenz.de)
 */
public class QueryGen {
	
	private static final String PATH_STATS = "path-stats.gz";
	private static final Random RAND = new Random(42);
	
	private PathStatistics pStats = new PathStatistics(RAND);
	
	
	public QueryGen() {
		
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		QueryGen gen = new QueryGen();
		
		gen.loadStatistics();
		gen.generateQueries(4, 4);
		
		// load statistics
		// load configuration
		// generate queries

	}
	
	public void loadStatistics() {
		try {
			pStats.loadPathStatistics(openReader(new File(PATH_STATS)));
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void generateQueries(int numPatterns, int numSources) {
		
		List<String> pathJoin = new ArrayList<String>();
		
		int[] choice = pStats.pickPathJoin();
		System.out.println("choice: " + Arrays.toString(choice));
		
//		while (pathJoin.size() < numPatterns) {
//			int[] joinComb = pickPathJoin();
//			
//		}
		
	}
	
//	private static <K> K getValue(Map<Integer, K> map, int key) {
//		K value = map.get(key);
//		if (value == null) {
//			value = (K) new HashMap<Integer, Object>();
//			map.put(key, value);
//		}
//		return value;
//	}
	
////	pred1, pred2, source1, source2, entityCount, triple1Count, triple2Count
//	public void loadPathStatistics(File file) {
//		try {
//			
//			long start = System.currentTimeMillis();
//			
//			BufferedReader reader = openReader(file);
//			
//			String line;
//			while ((line = reader.readLine()) != null) {
//				String[] parts = line.split(" ");
//
//				// p1 c1 p2 c2
//				int p1 = Integer.parseInt(parts[0]);
//				int c1 = Integer.parseInt(parts[1]);
//				int p2 = Integer.parseInt(parts[2]);
//				int c2 = Integer.parseInt(parts[3]);
//				
//				Map<Integer, Map<Integer, Map<Integer, List<Integer>>>> p1Stats;
//				Map<Integer, Map<Integer, List<Integer>>> c1Stats;
//				Map<Integer, List<Integer>> p2Stats;
//				List<Integer> c2Stats;
//				
//				p1Stats = pathStats.get(p1);
//				if (p1Stats == null) {
//					p1Stats = new TreeMap<Integer, Map<Integer, Map<Integer, List<Integer>>>>();
//					pathStats.put(p1, p1Stats);
//				}
//				c1Stats = p1Stats.get(c1);
//				if (c1Stats == null) {
//					c1Stats = new TreeMap<Integer, Map<Integer, List<Integer>>>();
//					p1Stats.put(c1, c1Stats);
//				}
//				p2Stats = c1Stats.get(p2);
//				if (p2Stats == null) {
//					p2Stats = new TreeMap<Integer, List<Integer>>();
//					c1Stats.put(p2, p2Stats);
//				}
//				c2Stats = p2Stats.get(c2);
//				if (c2Stats != null) {
//					System.err.println("not a unique path combination");
//				}
//				c2Stats = new ArrayList<Integer>();
//				c2Stats.add(Integer.parseInt(parts[4]));
//				c2Stats.add(Integer.parseInt(parts[5]));
//				c2Stats.add(Integer.parseInt(parts[6]));
//				p2Stats.put(c2, c2Stats);
//			}
//			
//			System.out.println("loaded " + pathStats.size() + " in " + ((System.currentTimeMillis() - start)/1000) + " secs");
//			
//		} catch (FileNotFoundException e) {
//			System.err.println("Error: file not found. " + e.getMessage());
//			System.exit(1);
//		} catch (IOException e) {
//			// TODO Auto-generated catch block
//			e.printStackTrace();
//		}
//	}

	private static final BufferedReader openReader(File file) throws FileNotFoundException, IOException {
		InputStream in = new FileInputStream(file);
		if (file.getName().endsWith(".gz"))
			in = new GZIPInputStream(in);
		return new BufferedReader(new InputStreamReader(in));
	}
	
//	public class PathStats {
//		
//		private int p1;  // predicate in base source
//		private int p2;  // predicate in target source
//		private int s1;  // base source
//		private int s2;  // target source
//		private int entities;        // number of entities connected via (p1@s1 -> p2@s2)
//		private int baseTriples;     // number of triples |p1@s1| referring to entities with (p2@s2) 
//		private int targetTriples;   // number of triples |p2@s2| with entities linked from (p1@s1)
//		
//		public void add(String[] stats) {
//			this.p1 = Integer.parseInt(stats[0]);
//			this.p2 = Integer.parseInt(stats[1]);
//			this.s1 = Integer.parseInt(stats[2]);
//			this.s2 = Integer.parseInt(stats[3]);
//			this.entities = Integer.parseInt(stats[4]);
//			this.baseTriples = Integer.parseInt(stats[5]);
//			this.targetTriples = Integer.parseInt(stats[6]);
//		}
//		
//	}
	
}
