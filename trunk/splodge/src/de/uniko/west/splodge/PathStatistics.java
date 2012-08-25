/*
 * This file is part of SPLODGE.
 * Copyright 2012 Olaf Goerlitz
 *
 * SPLODGE is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SPLODGE is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SPLODGE.  If not, see <http://www.gnu.org/licenses/>.
 */
package de.uniko.west.splodge;

import java.io.BufferedReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.TreeMap;

/**
 * Container for managing path statistics.
 * 
 * @author Olaf Goerlitz (goerlitz@uni-koblenz.de)
 */
public class PathStatistics {
	
	private Random rand;
	private Map<Integer, Map<Integer, Map<Integer, Map<Integer, List<Integer>>>>> pathStats;
	
	public PathStatistics(Random rand) {
		this.rand = rand;
		this.pathStats = new TreeMap<Integer, Map<Integer, Map<Integer, Map<Integer, List<Integer>>>>>();
	}
	
	public static final <K> K getKey(int index, Map<K, ?> map) {
		Iterator<K> it = map.keySet().iterator();
		for (int i = 0; i < index; i++) {
			it.next();
		}
		return it.next();
	}
	
	public int[] pickPathJoin() {
		int p1 = getKey(rand.nextInt(this.pathStats.size()), this.pathStats);
		Map<Integer, Map<Integer, Map<Integer, List<Integer>>>> c1Stats = this.pathStats.get(p1);
		int c1 = getKey(rand.nextInt(c1Stats.size()), c1Stats);
		
		return pickPathJoin(p1, c1);
	}
	
	public int[] pickPathJoin(int p1, int c1) {
		Map<Integer, Map<Integer, Map<Integer, List<Integer>>>> c1Stats = this.pathStats.get(p1);
		Map<Integer, Map<Integer, List<Integer>>> p2Stats = c1Stats.get(c1);
		int p2 = getKey(rand.nextInt(p2Stats.size()), p2Stats);
		Map<Integer, List<Integer>> c2Stats = p2Stats.get(p2);
		int c2 = getKey(rand.nextInt(c2Stats.size()), c2Stats);
		
		return new int[] { p1, c1, p2, c2 };
	}
	
	public boolean exists(int p1, int c1) {
		return pathStats.get(p1) != null && pathStats.get(p1).get(c1) != null;
	}
	
//	pred1, pred2, source1, source2, entityCount, triple1Count, triple2Count
	public void loadPathStatistics(BufferedReader reader) {
		try {
			
			System.out.println("loading path statistics");
			long start = System.currentTimeMillis();
			
			String line;
			while ((line = reader.readLine()) != null) {
				String[] parts = line.split(" ");

				// p1 c1 p2 c2
				int p1 = Integer.parseInt(parts[0]);
				int c1 = Integer.parseInt(parts[1]);
				int p2 = Integer.parseInt(parts[2]);
				int c2 = Integer.parseInt(parts[3]);
				
				Map<Integer, Map<Integer, Map<Integer, List<Integer>>>> p1Stats;
				Map<Integer, Map<Integer, List<Integer>>> c1Stats;
				Map<Integer, List<Integer>> p2Stats;
				List<Integer> c2Stats;
				
				p1Stats = pathStats.get(p1);
				if (p1Stats == null) {
					p1Stats = new TreeMap<Integer, Map<Integer, Map<Integer, List<Integer>>>>();
					pathStats.put(p1, p1Stats);
				}
				c1Stats = p1Stats.get(c1);
				if (c1Stats == null) {
					c1Stats = new TreeMap<Integer, Map<Integer, List<Integer>>>();
					p1Stats.put(c1, c1Stats);
				}
				p2Stats = c1Stats.get(p2);
				if (p2Stats == null) {
					p2Stats = new TreeMap<Integer, List<Integer>>();
					c1Stats.put(p2, p2Stats);
				}
				c2Stats = p2Stats.get(c2);
				if (c2Stats != null) {
					System.err.println("not a unique path combination");
				}
				c2Stats = new ArrayList<Integer>();
				c2Stats.add(Integer.parseInt(parts[4]));
				c2Stats.add(Integer.parseInt(parts[5]));
				c2Stats.add(Integer.parseInt(parts[6]));
				p2Stats.put(c2, c2Stats);
			}
			
			System.out.println("loaded path stats in " + ((System.currentTimeMillis() - start)/1000) + " secs");
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
